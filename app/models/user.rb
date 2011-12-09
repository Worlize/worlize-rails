class User < ActiveRecord::Base
  before_create :assign_guid
  before_create :initialize_default_slots
  after_create :initialize_currency
  before_destroy :unlink_friendships
  
  scope :active, lambda {
    where(:suspended => false)
  }
  
  has_many :authentications, :dependent => :destroy
  
  has_many :worlds, :dependent => :destroy
  has_many :background_instances, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :avatar_instances, :dependent => :nullify
  has_many :prop_instances, :dependent => :nullify
  
  has_many :virtual_financial_transactions, :dependent => :restrict, :order => 'created_at'
  has_many :payments, :dependent => :restrict, :order => 'created_at'
  
  has_many :created_avatars, :foreign_key => 'creator_id', :dependent => :nullify, :class_name => 'Avatar'
  
  has_many :received_gifts, :class_name => 'Gift', :foreign_key => 'recipient_id'
  has_many :sent_gifts,     :class_name => 'Gift', :foreign_key => 'sender_id'
  
  has_many :sharing_links, :dependent => :destroy
  
  belongs_to :inviter, :class_name => 'User'
  
  belongs_to :beta_code
  
  attr_accessible :username,
                  :email,
                  :accepted_tos
                  
  attr_accessor :accessible
  
  # validates :birthday, :timeliness => {
  #       :before => :thirteen_years_ago,
  #       :type => :date
  #   }

  state_machine :initial => :new_user do
    
    event :first_time_login do
      transition :new_user => :user_ready
    end
    
  end

  acts_as_authentic do |c|
    c.login_field = 'username'
    c.validates_format_of_login_field_options = {
      :with => /^[a-zA-Z\d_\-\ ]+$/,
      :message => 'can only contain letters, numbers, spaces, and the dash or underscore characters'
    }
    c.validate_password_field = false
    c.validates_uniqueness_of_email_field_options = {
      :if => Proc.new { |user| false }
    }
  end
  
  def active?
    !self.suspended?
  end
  
  def public_hash_for_api
    {
      :guid => self.guid,
      :username => self.username,
      :created_at => self.created_at
    }
  end
  
  def hash_for_api
    world = self.worlds.first
    self.public_hash_for_api.merge(
      :background_slots => self.background_slots,
      :avatar_slots => self.avatar_slots,
      :prop_slots => self.prop_slots,
      :in_world_object_slots => self.in_world_object_slots,
      :coins => self.coins,
      :bucks => self.bucks,
      :twitter => self.twitter,
      :email => self.email,
      :birthday => self.birthday,
      :picture => self.profile_picture,
      :world_entrance => world.rooms.first.guid,
      :world_name => world.name,
      :world_guid => world.guid
    )
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
  
  def permissions
    if self.admin?
      [
        :may_author_everything
      ]
    else
      []
    end
  end
  
  def add_to_mailchimp
    if Rails.env != 'production'
      Rails.logger.info "Not adding #{self.email} to MailChimp because we're not in production"
      return true
    end

    result = false
    
    begin    
      if !self.first_name.nil? && !self.last_name.nil?
        full_name = self.first_name + " " + self.last_name
      elsif self.facebook_authentication && !self.facebook_authentication.display_name.nil?
        full_name = self.facebook_authentication.display_name
      elsif self.twitter_authentication && !self.twitter_authentication.display_name.nil?
        full_name = self.twitter_authentication.display_name
      else
        full_name = 'Worlize User'
      end

      gb = Gibbon.new(Worlize.config['mailchimp']['api_key'])
      result = gb.listSubscribe({
        'id' => Worlize.config['mailchimp']['all_users_list_id'],
        'email_address' => self.email,
        'merge_vars' => {
          'FULLNAME' => full_name,
          'USERNAME' => self.username,
          'EUSERNAME' => URI.escape(self.username)
        },
        'double_optin' => false,
        'send_welcome' => false
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
    
    if result[0] > 0 || result[1] > 0
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
    (result[0] == 1) || (result[1] == 1)
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
  
  def recalculate_balances
    self.coins = self.virtual_financial_transactions.sum('coins_amount')
    self.bucks = self.virtual_financial_transactions.sum('bucks_amount')
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
      :server_id => server_id
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
  
  private
  
  def mass_assignment_authorizer
    if accessible == :all
      self.class.protected_attributes
    else
      super + (accessible || [])
    end
  end
  
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
    self.prop_slots = 20
    self.background_slots = 10
    self.avatar_slots = 20
    self.in_world_object_slots = 25
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
end
