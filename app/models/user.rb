class User < ActiveRecord::Base
  before_create :assign_guid
  before_create :initialize_default_slots
  after_create :initialize_currency
  after_create :log_creation
  before_destroy :unlink_friendships
  before_save :synchronize_username_changed_at
  after_save :update_interactivity_session, :notify_users_of_changes
  
  scope :active, lambda {
    where(:suspended => false)
  }
  
  has_many :authentications, :dependent => :destroy
  
  has_many :worlds, :dependent => :destroy
  has_many :background_instances, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :app_instances, :dependent => :nullify
  has_many :avatar_instances, :dependent => :nullify
  has_many :prop_instances, :dependent => :nullify
  
  has_many :virtual_financial_transactions, :dependent => :restrict, :order => 'created_at'
  has_many :payments, :dependent => :restrict, :order => 'created_at'
  
  has_many :created_avatars, :foreign_key => 'creator_id', :dependent => :nullify, :class_name => 'Avatar'
  
  has_many :received_gifts, :class_name => 'Gift', :foreign_key => 'recipient_id'
  has_many :sent_gifts,     :class_name => 'Gift', :foreign_key => 'sender_id'
  
  has_many :marketplace_item_giveaway_receipts, :dependent => :destroy
  
  has_many :sharing_links, :dependent => :destroy
  
  belongs_to :inviter, :class_name => 'User'
  
  belongs_to :beta_code
  
  has_many :user_restrictions
  
  has_many :event_comments
  
  attr_accessor :skip_password_requirement
  
  attr_accessible :username,
                  :login_name,
                  :email,
                  :newsletter_optin,
                  :accepted_tos,
                  :password,
                  :password_confirmation,
                  :birthday
                  
  attr_accessible :username,
                  :email,
                  :newsletter_optin,
                  :accepted_tos,
                  :password,
                  :password_confirmation,
                  :developer,
                  :avatar_slots,
                  :background_slots,
                  :in_world_object_slots,
                  :prop_slots,
                  :app_slots,
                  :as => :admin
                  
  validates :birthday, :timeliness => {
    :before => :thirteen_years_ago,
    :type => :date
  }
  
  validates :avatar_slots, :numericality => {
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { !self.new_record? }
  }
  validates :background_slots, :numericality => {
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { !self.new_record? }
  }
  validates :in_world_object_slots, :numericality => {
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { !self.new_record? }
  }
  validates :app_slots, :numericality => {
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { !self.new_record? }
  }
  validates :prop_slots, :numericality => {
    :greater_than_or_equal_to => 0, 
    :if => Proc.new { !self.new_record? }
  }

  validates :password,
    :confirmation => true,
    :presence => {
      :if => Proc.new { self.state?(:new_user) && !self.skip_password_requirement }
    }
  
  validates :username,
    :uniqueness => {
      :case_sensitive => false, 
      :if => Proc.new { self.username_changed? }
    },
    :length => {
      :in => 3..36
    },
    :format => {
      :with => /^[a-zA-Z0-9_\-\ ]+$/,
      :message => "can only contain letters, numbers, spaces, and the dash or underscore characters"
    }
  
  validates :accepted_tos, :inclusion => {
    :in => [true],
    :if => Proc.new { self.state?(:new_user) },
    :message => "must be checked"
  }
  
  validate :username_cannot_have_been_changed_in_the_last_month

  state_machine :initial => :new_user do
    event :first_time_login do
      transition :new_user => :user_ready
    end
    
    event :confirm_login_name do
      transition :login_name_unconfirmed => :user_ready
    end
    
    before_transition :new_user => any do |user, transition|
      # Let the user change their password once after signup
      user.username_changed_at = nil
      
      # Update the password last changed date
      user.password_changed_at = Time.now unless user.crypted_password.nil?
    end
  end

  acts_as_authentic do |c|
    c.login_field = 'login_name'
    c.validates_length_of_login_field_options = {
      :in => 3..50
    }
    c.validates_format_of_login_field_options = {
      :with => /^[a-zA-Z0-9_\-]+$/,
      :message => 'can only contain letters, numbers, and the dash or underscore characters'
    }
    c.validate_password_field = false

    # We're now requiring email addresses to be unique.
    # c.validates_uniqueness_of_email_field_options = {
    #   :if => Proc.new { |user| false }
    # }
    
    c.validates_uniqueness_of_email_field_options = {
      :case_sensitive => false,
      :message => "is already in use by an existing account.",
      :if => Proc.new { self.email_changed? }
    }
  end
  
  def self.global_moderators
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    guids = redis.zrange('gml', '0', '-1')
    self.where(:guid => guids).order(:username)
  end
    
  def active?
    !self.suspended?
  end
  
  def public_hash_for_api
    {
      :guid => self.guid,
      :username => self.username,
      :created_at => self.created_at.utc
    }
  end
  
  def hash_for_api
    world = self.worlds.first
    data = {
      :name => self.name,
      :password_changed_at => self.password_changed_at.nil? ? nil : self.password_changed_at.utc,
      :developer => self.developer?,
      :background_slots => self.background_slots,
      :avatar_slots => self.avatar_slots,
      :prop_slots => self.prop_slots,
      :in_world_object_slots => self.in_world_object_slots,
      :app_slots => self.app_slots,
      :coins => self.coins,
      :bucks => self.bucks,
      :email => self.email,
      :birthday => self.birthday,
      :picture => self.profile_picture,
      :world_entrance => world.rooms.first.guid,
      :world_name => world.name,
      :world_guid => world.guid,
      :authentications => self.authentications.map { |auth| auth.hash_for_api }
    }
    self.public_hash_for_api.merge(data)
  end
  
  def hash_for_friends_list(type='full')
    friend_data = {
      :friend_type => 'worlize',
      :picture => self.profile_picture,
      :guid => self.guid,
      :username => self.username,
      :name => self.name,
      :presence_status => self.presence_status
    }
    friend_data[:facebook_profile] = self.facebook_profile_url
    friend_data[:twitter_profile] = self.twitter_profile_url
    if facebook_authentication
      friend_data[:facebook_id] = facebook_authentication.uid
    end
    if type == 'full'
      friend_data[:auto_synced] = false
      if self.worlds.first && self.worlds.first.rooms.first
        friend_data[:world_entrance] = self.worlds.first.rooms.first.guid
      end
    end
    friend_data
  end
  
  # If a facebook full name is available, use that.  Otherwise, mirror
  # the username field
  def name
    if facebook_authentication && facebook_authentication.display_name
      return facebook_authentication.display_name
    end
    return username
  end
  
  # Profile picture is determined in order of precedence:
  # 1.) Explicitly set avatar image for profile picture (not implemented yet)
  # 2.) Facebook profile picture
  # 3.) unknown_user.png
  def profile_picture
    if facebook_authentication && facebook_authentication.profile_picture
      return facebook_authentication.profile_picture
    end
    return '/images/unknown_user.png'
  end
  
  def profile_picture_small
    if facebook_authentication && facebook_authentication.profile_picture
      return facebook_authentication.profile_picture
    end
    return '/images/unknown_user_small.png'
  end
  
  def facebook_profile_url
    if self.facebook_authentication
      return (self.facebook_authentication.profile_url ||
       "https://www.facebook.com/#{self.facebook_authentication.uid}")
    end
    return nil
  end
  
  def twitter_profile_url
    if self.twitter_authentication
      return self.twitter_authentication.profile_url
    end
    return nil
  end

  def total_time_spent_online
    redis = Worlize::RedisConnectionPool.get_client(:stats)
    redis.zscore('userTime', self.guid).to_i
  end
  
  def is_global_moderator?
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.sismember("global_moderators", self.guid)
  end
  
  def is_moderator_for_world?(world_or_guid)
    world = world_or_guid.is_a?(World) ? world_or_guid : World.find_by_guid(world_or_guid)
    raise "You must specify a world or world guid" if world.nil?
    world.user_is_moderator?(self)
  end
  
  def set_as_global_moderator
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.sadd("global_moderators", self.guid)
  end
  
  def unset_as_global_moderator
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    redis.srem("global_moderators", self.guid)
  end

  def total_time_spent_online_hms
    t = self.total_time_spent_online
    mm, ss = t.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    "%d:%02d:%02d:%02d" % [dd, hh, mm, ss]
  end
  
  def total_time_spent_online_hms_long
    t = self.total_time_spent_online
    mm, ss = t.divmod(60)
    hh, mm = mm.divmod(60)
    dd, hh = hh.divmod(24)
    "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
  end

  # Old create_world deprecated
  def create_world
    world = self.worlds.create(:name => "#{self.username.capitalize}'s World")
    template_world = World.find_by_guid(World.initial_template_world_guid)

    # Fall back to basic world creation if template world isn't available
    initialize_world_first_room and return if template_world.nil?
    
    world.add_rooms_from_template_world(template_world)
  end
  
  def initialize_world_first_room
    world = self.worlds.first
    default_background_guid = Background.initial_world_background_guid
    default_background = Background.find_by_guid(default_background_guid)
    if default_background.nil?
      raise 'Unable to find the default world background'
    end  
    
    # Initialize user's first background instance
    bi = self.background_instances.create(:background => default_background)
    
    room = world.rooms.create(:name => "Entrance")
    room.background_instance = bi
    room.save
  end
  
  def add_to_mailchimp
    if Rails.env != 'production'
      Rails.logger.info "Not adding #{self.email} to MailChimp because we're not in production"
      return true
    end

    result = false
    
    begin    
      gb = Gibbon.new(Worlize.config['mailchimp']['api_key'])
      result = gb.listSubscribe({
        'id' => Worlize.config['mailchimp']['all_users_list_id'],
        'email_address' => self.email,
        'merge_vars' => {
          'NAME' => self.name,
          'USERNAME' => self.username,
          'EUSERNAME' => URI.escape(self.username)
        },
        'double_optin' => false,
        'send_welcome' => true
      })
    
      if result
        Rails.logger.info "#{self.email} added to the MailChimp All Users list."
      else
        Rails.logger.info "Unable to add #{self.email} to the MailChimp All Users list."
      end
    rescue
    end
    return result
  end
  
  def online?
    presence_status == 'online'
  end
  
  # there is no setter for this because presence_status is maintained by the
  # presence server.  Any other mechanism attempting to change it would be in
  # conflict with the canonical data source.
  def presence_status
    # Memoize for the life of the instance to help with sorting...
    return @presence_status unless @presence_status.nil?
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    result = redis.get("status:#{self.guid}")
    
    # an 'offline' status is represented by the absense of a key in Redis
    # ... why waste prescious memory on users that aren't online?
    return @presence_status = 'offline' if result.nil?
    
    statuses = [
      'offline', # 'offline' is also optionally represented by a zero value
      'online',
      'idle',
      'away',
      'invisible'
    ]
    @presence_status = statuses[result.to_i]
  end
  
  def current_room_guid
    self.interactivity_session.room_guid
  end
  
  def main_world_entrance
    main_world = self.worlds.first
    if main_world
      world_entrance = main_world.rooms.first
      return world_entrance if world_entrance
    end
    
    # If we can't find the user's main world entrance, return the main gate
    gate_room = Room.find_by_guid(Room.gate_room_guid)
    return gate_room if gate_room
    
    # If there's not even a gate room, return the first room we can find!?!
    return Room.first
  end
  
  def send_message(message)
    Worlize::PubSub.publish("user:#{self.guid}", message)
  end
  
  def can_edit?(item)
    if item.respond_to? 'can_be_edited_by?'
      item.can_be_edited_by?(self)
    else
      false
    end
  end
  
  def facebook_authentication
    return @facebook_authentication if @facebook_authentication
    self.authentications.each do |auth|
      if auth.provider == 'facebook'
        return @facebook_authentication = auth
      end
    end
    return nil
  end
  
  def twitter_authentication
    return @twitter_authentication if @twitter_authentication
    self.authentications.each do |auth|
      if auth.provider == 'twitter'
        return @twitter_authentication = auth
      end
    end
    return nil
  end
  
  ###################################################################
  ##  Friendship Functions                                         ##
  ###################################################################
  
  def request_friendship_of(potential_friend, picture_base_url='')
    if self.is_friends_with?(potential_friend)
      Rails.logger.info "#{self.username} requested friendship with existing friend #{potential_friend.username}"
      return false
    end
    if self.accept_friendship_request_from(potential_friend)
      return true
    end
    if redis_relationships.sadd "#{potential_friend.guid}:friendRequests", self.guid
      potential_friend.send_message({
        :msg => 'new_friend_request',
        :data => {
          :user => {
            :guid => self.guid,
            :username => self.username,
            :picture => "#{picture_base_url}/images/unknown_user.png",
          }
        }
      })
      
      if !potential_friend.online?
        email = EventNotifier.new_friend_request_email({
          :sender => self,
          :recipient => potential_friend
        })
        email.deliver
      end
    end
    true
  end
  
  def has_requested_friendship_of?(potential_friend)
    redis_relationships.sismember "#{potential_friend.guid}:friendRequests", self.guid
  end
  
  def retract_friendship_request_for(potential_friend)
    redis_relationships.srem "#{potential_friend.guid}:friendRequests", self.guid
  end
  
  def reject_friendship_request_from(rejected_friend)
    redis_relationships.srem "#{self.guid}:friendRequests", rejected_friend.guid
    # Let's avoid sending an embarrassing "You've been rejected" message...
  end
  
  def accept_friendship_request_from(accepted_friend, picture_base_url='')
    result = redis_relationships.srem "#{self.guid}:friendRequests", accepted_friend.guid
    if result
      self.befriend(accepted_friend)
      
      accepted_friend.send_message({
        :msg => 'friend_request_accepted',
        :data => {
          :user => self.hash_for_friends_list
        }
      })
      return true
    end
    return false
  end

  def pending_friend_guids
    redis_relationships.smembers "#{self.guid}:friendRequests"
  end
  
  def pending_friends
    User.find_all_by_guid(self.pending_friend_guids, :order => 'username')
  end
  
  def pending_friend_count
    redis_relationships.scard "#{self.guid}:friendRequests"
  end
  
  def befriend(new_friend, options={})
    if !options.has_key?(:send_notification)
      options[:send_notification] = true
    end
    if !options.has_key?(:facebook_friend)
      options[:facebook_friend] = false
    end

    result = redis_relationships.multi do
      if options[:facebook_friend]
        redis_relationships.sadd "#{self.guid}:fbFriends", new_friend.guid
        redis_relationships.sadd "#{new_friend.guid}:fbFriends", self.guid
      else
        redis_relationships.sadd "#{self.guid}:friends", new_friend.guid
        redis_relationships.sadd "#{new_friend.guid}:friends", self.guid
      end

      # If we're explicitly adding a new friend, we need to make
      # sure they're no longer in the list of friends not to auto-sync.
      redis_relationships.srem("#{self.guid}:nosyncFriends", new_friend.guid)
    end
    
    if result[0] || result[1]
      if options[:send_notification]
        # send notification to current user
        self.send_message({
          :msg => 'friend_added',
          :data => {
            :facebook_friend => options[:facebook_friend],
            :user => {
              :guid => new_friend.guid,
              :username => new_friend.username
            }
          }
        })
        # send notification to new friend
        new_friend.send_message({
          :msg => 'friend_added',
          :data => {
            :facebook_friend => options[:facebook_friend],
            :user => {
              :guid => self.guid,
              :username => self.username
            }
          }
        })
      end
      return true
    end

    return false
  end
  
  def unfriend(sworn_enemy, options={})
    if sworn_enemy.instance_of? String
      sworn_enemy = User.find_by_guid(sworn_enemy)
      if sworn_enemy.nil?
        return false
      end
    end
    
    if !options.has_key?(:prevent_add_on_next_sync)
      options[:prevent_add_on_next_sync] = true
    end
    
    if redis_relationships.sismember("#{self.guid}:fbFriends", sworn_enemy.guid)
      # Facebook friend
      facebook = true

    elsif redis_relationships.sismember("#{self.guid}:friends", sworn_enemy.guid)
      # Worlize friend
      facebook = false
    else
      # Not a friend
      return false
    end

    if options[:prevent_add_on_next_sync]
      # Add this member to a list of Facebook friends that have been removed
      # intentionally so they don't get re-added on the next sync
      redis_relationships.sadd("#{self.guid}:nosyncFriends", sworn_enemy.guid)
    end
    
    redis_relationships.multi do
      if facebook
        redis_relationships.srem "#{self.guid}:fbFriends", sworn_enemy.guid
        redis_relationships.srem "#{sworn_enemy.guid}:fbFriends", self.guid
      else
        redis_relationships.srem "#{self.guid}:friends", sworn_enemy.guid
        redis_relationships.srem "#{sworn_enemy.guid}:friends", self.guid
      end
    end
    sworn_enemy.send_message({
      :msg => 'friend_removed',
      :data => {
        :show_notification => false,
        :user => {
          :guid => self.guid,
          :username => self.username
        }
      }
    })
    self.send_message({
      :msg => 'friend_removed',
      :data => {
        :show_notification => true,
        :user => {
          :guid => sworn_enemy.guid,
          :username => sworn_enemy.username
        }
      }
    })
    true
  end
  
  def mutual_friend_guids_with(user)
    self.friend_guids & user.friend_guids # intersection
  end

  def mutual_friends_with(user)
    User.where(:guid => self.mutual_friend_guids_with(user))
  end
  
  def is_mutual_friends_with?(user1, user2)
    user1.mutual_friend_guids_with(user2).include? self.guid
  end
  
  def is_friends_with?(user)
    result = redis_relationships.multi do
      redis_relationships.sismember "#{self.guid}:friends", user.guid
      redis_relationships.sismember "#{self.guid}:fbFriends", user.guid
    end
    (result[0]) || (result[1])
  end
  
  def nosync_friend_guids
    redis_relationships.smembers("#{self.guid}:nosyncFriends")
  end
  
  def nosync_friend?(possible_friend)
    redis_relationships.sismember("#{self.guid}:nosyncFriends", possible_friend.guid)
  end
  
  def facebook_friend_guids
    redis_relationships.smembers "#{self.guid}:fbFriends"
  end
  
  def worlize_friend_guids
    redis_relationships.smembers "#{self.guid}:friends"
  end
  
  def friend_guids
    redis_relationships.sunion "#{self.guid}:friends", "#{self.guid}:fbFriends"
  end
  
  # Returns both facebook and explicit worlize friends
  def friends
    User.where(:guid => self.friend_guids)
  end
  
  # Returns only facebook friends
  def facebook_friends
    User.where(:guid => self.facebook_friend_guids)
  end

  # Returns only worlize friends
  def worlize_friends
    User.where(:guid => self.worlize_friend_guids)
  end

  
  ###################################################################
  ##  Financial Functions                                          ##
  ###################################################################
  
  def coins
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.get("coins:#{self.guid}").to_i
  end
  
  def bucks
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.get("bucks:#{self.guid}").to_i
  end
  
  def coins=(new_value)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.set("coins:#{self.guid}", new_value)
  end
  
  def bucks=(new_value)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.set("bucks:#{self.guid}", new_value)
  end
  
  def add_coins(amount)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.incrby("coins:#{self.guid}", amount)
  end
  
  def subtract_coins(amount)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.decrby("coins:#{self.guid}", amount)
  end

  def add_bucks(amount)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.incrby("bucks:#{self.guid}", amount)
  end
  
  def subtract_bucks(amount)
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.decrby("bucks:#{self.guid}", amount)
  end
  
  def notify_client_of_balance_change
    # send notification to current user
    self.send_message({
      :msg => 'balance_updated',
      :data => {
        :coins => self.coins,
        :bucks => self.bucks
      }
    })
  end
  
  def notify_client_of_slots_change
    self.send_message({
      :msg => 'slots_updated',
      :data => {
        :avatar_slots => self.avatar_slots,
        :background_slots => self.background_slots,
        :in_world_object_slots => self.in_world_object_slots,
        :app_slots => self.app_slots,
        :prop_slots => self.prop_slots
      }
    })
  end
  
  def recalculate_balances
    self.coins = self.virtual_financial_transactions.sum('coins_amount')
    self.bucks = self.virtual_financial_transactions.sum('bucks_amount')
  end
  
  def buy_slots(slot_kind, quantity)
    # Make sure slot_kind is valid
    unless (['avatar','in_world_object','background','prop','app'].include?(slot_kind))
      raise StandardError.new("#{slot_kind} is not a valid slot_kind.")
    end
    
    quantity = quantity.to_i
    if quantity <= 0
      raise StandardError.new("You must specify a valid quantity of slots to buy")
    end
    
    # Look up the price
    price = LockerSlotPrice.find_by_slot_kind(slot_kind)
    if price.nil?
      raise StandardError.new("Unable to look up pricing information for locker slots.")
    end

    # Make sure the user has enough money
    if self.bucks < (price.bucks_amount * quantity)
      raise Worlize::InsufficientFundsException.new("You do not have enough Worlize Bucks to complete your purchase.")
    end
    
    # Charge the customer
    VirtualFinancialTransaction.transaction do
      transaction = VirtualFinancialTransaction.new(
        :user => self,
        :kind => VirtualFinancialTransaction::KIND_DEBIT_SLOT_PURCHASE,
        :bucks_amount => 0 - price.bucks_amount * quantity,
        :comment => "Purchased #{quantity} #{slot_kind.humanize} Slot" + (quantity == 1 ? '' : 's')
      )
      transaction.save!
      
      # Put the product into the user's locker...
      existing_slots = self.send("#{slot_kind}_slots")
      self.send("#{slot_kind}_slots=", existing_slots + quantity)
      self.save!
      
      self.recalculate_balances
      self.notify_client_of_balance_change
      self.notify_client_of_slots_change
    end
    self.send("#{slot_kind}_slots")
  end
  
  ###################################################################
  ##  END: Financial Functions                                     ##
  ###################################################################
  

  def interactivity_session
    s = InteractivitySession.find_by_user_guid(self.guid)
    return s unless s.nil?
    world = self.worlds.first
    room = world.rooms.first
    server_id = room.interact_server_id
    s = InteractivitySession.new
    s.update_attributes(
      :username => self.username,
      :user_guid => self.guid,
      :room_guid => room.guid,
      :world_guid => world.guid,
      :server_id => server_id,
      :facebook_id => facebook_authentication.nil? ? nil : facebook_authentication.uid
    )
    return s
  end
  
  def reset_appearance!
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    redis.del("userState:#{self.guid}")
  end
  
  def disable_webcam!
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    userStateJSON = redis.get("userState:#{self.guid}")
    if userStateJSON
      begin
        userState = Yajl::Parser.parse(userStateJSON)
        if userState['avatar']['type'] == 'video'
          userState['avatar'] = nil
          redis.set("userState:#{self.guid}", Yajl::Encoder.encode(userState))
          redis.expire("userState:#{self.guid}", 60*60*24); # 24 hours
        end
      rescue
        redis.del("userState:#{self.guid}")
      end
    end
  end
  
  ###################################################################
  ## Permissions
  ###################################################################
  
  def applied_permissions(world_guid)
    permissions(world_guid, true)
  end
  
  def permissions(world_guid=nil, do_union=false)
    if !world_guid.nil? && worlds.first.guid == world_guid
      # A user always has all permissions within their own world
      return Worlize::PermissionLookup.world_owner_permission_names.clone
    end
    
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    
    if world_guid.nil?
      permissions = redis.smembers("g:#{self.guid}")
    elsif do_union
      permissions = redis.sunion("g:#{self.guid}", "w:#{world_guid}:#{self.guid}")
    else
      permissions = redis.smembers("w:#{world_guid}:#{self.guid}")
    end
    
    permission_names = permissions.map do |permission_id|
      Worlize::PermissionLookup.permission_map[permission_id]
    end
    
    permission_names.select do |permission_name|
      !permission_name.nil?
    end
  end
  
  def set_permissions(list, world_guid=nil)
    if !list.is_a?(Array)
      raise ArgumentError.new("Permission list must be an array")
    end
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    list = list.map { |perm| Worlize::PermissionLookup.normalize_to_permission_id(perm) }
    
    redis_key = world_guid.nil? ? "g:#{self.guid}" : "w:#{world_guid}:#{self.guid}"
    
    redis.multi do
      redis.del redis_key
      list.each do |perm|
        redis.sadd redis_key, perm
      end
    end
    
    update_moderator_list(world_guid)
    broadcast_user_permissions_changed_message(world_guid)
    return self.permissions(world_guid)
  end
  
  def add_permission(new_permission, world_guid=nil)
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    if world_guid.nil?
      redis.sadd("g:#{self.guid}", Worlize::PermissionLookup.normalize_to_permission_id(new_permission))
    else
      redis.sadd("w:#{world_guid}:#{self.guid}", Worlize::PermissionLookup.normalize_to_permission_id(new_permission))
    end
    update_moderator_list(world_guid)
    broadcast_user_permissions_changed_message(world_guid)
    return self.permissions(world_guid)
  end
  
  def remove_permission(permission, world_guid=nil)
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    redis.srem("g:#{self.guid}", Worlize::PermissionLookup.normalize_to_permission_id(permission))
    update_moderator_list(world_guid)
    broadcast_user_permissions_changed_message(world_guid)
    return self.permissions(world_guid)
  end
  
  def update_moderator_list(world_guid=nil)
    redis = Worlize::RedisConnectionPool.get_client(:permissions)
    permission_count = permissions(world_guid).length
    redis.multi do
      if world_guid.nil?
        redis.zadd 'gml', permission_count, self.guid
        redis.zremrangebyscore 'gml', '-inf', '0'
      else
        redis.zadd "wml:#{world_guid}", permission_count, self.guid
        redis.zremrangebyscore "wml:#{world_guid}", '-inf', '0'
      end
    end
    nil
  end
  
  def broadcast_user_permissions_changed_message(world_guid=nil)
    # Broadcast update is only relevant if the user is online
    if online?
      # Broadcast to the world that the user is currently in...
      Worlize::InteractServerManager.instance.broadcast_to_world(
        interactivity_session.world_guid,
        {
          :msg => 'user_permissions_changed',
          :data => {
            :guid => self.guid
          }
        }
      )
    end
  end
  
  private
  
  def redis_relationships
    @redis_relationships ||= Worlize::RedisConnectionPool.get_client(:relationships)
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def initialize_currency
    self.coins = Worlize.config['initial_currency']['coins'] || 0
    self.bucks = Worlize.config['initial_currency']['bucks'] || 0
    
    if self.coins > 0
      self.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :coins_amount => self.coins,
        :comment => "Initial Balance"
      )
    end
    
    if self.bucks > 0
      self.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :bucks_amount => self.bucks,
        :comment => "Initial Balance"
      )
    end
  end
  
  def initialize_default_slots
    self.prop_slots = 10000
    self.background_slots = 10000
    self.avatar_slots = 10000
    self.in_world_object_slots = 10000
    self.app_slots = 10000
  end
  
  def avatar_slots_used
    self.avatar_instances.count
  end
  
  def background_slots_used
    self.background_instances.count
  end
  
  def in_world_object_slots_used
    self.in_world_object_instances.count
  end
  
  def app_slots_used
    self.app_instances.count
  end
  
  def prop_slots_used
    self.prop_instances.count
  end
  
  def unlink_friendships
    self.friend_guids.each do |friend_guid|
      redis_relationships.multi do
        redis_relationships.srem "#{self.guid}:friends", friend_guid
        redis_relationships.srem "#{self.guid}:fbFriends", friend_guid
        redis_relationships.srem "#{friend_guid}:friends", self.guid
        redis_relationships.srem "#{friend_guid}:fbFriends", self.guid
      end
    end
  end
  
  def log_creation
    Worlize.event_logger.info("action=user_created user=#{self.guid} user_username=\"#{self.username}\"")
  end
  
  def update_interactivity_session
    if !new_user? && username_changed?
      interactivity_session.update_attributes(:username => username)
    end
  end
  
  def notify_users_of_changes
    if username_changed? && online?
      Worlize::InteractServerManager.instance.broadcast_to_world(
        interactivity_session.world_guid,
        {
          :msg => 'user_updated',
          :data => public_hash_for_api
        }
      )
      
      message = {
        :msg => 'friend_data_updated',
        :data => hash_for_friends_list
      }
      friend_guids.each do |friend_guid|
        Worlize::PubSub.publish("user:#{friend_guid}", message)
      end
    end
  end
  
  def username_cannot_have_been_changed_in_the_last_month
    if self.username_changed?
      if self.username_changed_at != nil && self.username_changed_at > 30.days.ago
        errors.add(:username, "can only be changed once every 30 days.");
      end
    end
  end
  
  def synchronize_username_changed_at
    if self.username_changed?
      self.username_changed_at = Time.now
    end
  end
end
