class User < ActiveRecord::Base
  before_create :assign_guid
  before_create :initialize_default_slots
  after_create :initialize_currency
  before_destroy :unlink_friendships
  
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
                  :password,
                  :password_confirmation,
                  :email,
                  :birthday,
                  :twitter,
                  :first_name,
                  :last_name
  
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :birthday, :timeliness => {
      :before => :thirteen_years_ago,
      :type => :date
  }
  validates :email, { :presence => true,
                      :email => true,
                      :uniqueness => {
                        :message => "has already been used"
                      }
                    }
  
  state_machine :initial => :new_user do
    
    event :first_time_login do
      transition :new_user => :linking_external_accounts
    end
    
    event :finish_linking_external_accounts do
      transition :linking_external_accounts => :user_ready
    end
    
  end

  acts_as_authentic do |c|
    #config options here
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
      :first_name => self.first_name,
      :last_name => self.last_name,
      :background_slots => self.background_slots,
      :avatar_slots => self.avatar_slots,
      :prop_slots => self.prop_slots,
      :in_world_object_slots => self.in_world_object_slots,
      :coins => self.coins,
      :bucks => self.bucks,
      :twitter => self.twitter,
      :email => self.email,
      :birthday => self.birthday,
      :world_entrance => world.rooms.first.guid,
      :world_name => world.name,
      :world_guid => world.guid
    )
  end

  def create_world
    world = self.worlds.create(:name => "#{self.username.capitalize}'s World")
    
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
  
  def current_server_id
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    redis.get "interactServerForUser:#{self.guid}"
  end
  
  def online?
    # Memoize for the life of the instance to help with sorting...
    return @online unless @online.nil?
    redis = Worlize::RedisConnectionPool.get_client(:presence)
  
    # Find the last server they were connected to...
    server_id = redis.get "interactServerForUser:#{self.guid}"
    return false if server_id.nil?
  
    # ...and see if they're still there.
    @online = redis.sismember "connectedUsers:#{server_id}", self.guid
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
  
  
  ###################################################################
  ##  Friendship Functions                                         ##
  ###################################################################
  
  def request_friendship_of(potential_friend)
    return false if self.is_friends_with?(potential_friend)
    return true if self.accept_friendship_request_from(potential_friend)
    if redis_relationships.sadd "#{potential_friend.guid}:friendRequests", self.guid
      potential_friend.send_message({
        :msg => 'new_friend_request',
        :data => {
          :user => {
            :guid => self.guid,
            :username => self.username
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
  
  def accept_friendship_request_from(accepted_friend)
    result = redis_relationships.srem "#{self.guid}:friendRequests", accepted_friend.guid
    if result
      self.befriend(accepted_friend)
      accepted_friend.send_message({
        :msg => 'friend_request_accepted',
        :data => {
          :user => {
            :guid => self.guid,
            :username => self.username,
            :online => self.online?,
            :world_entrance =>
              (self.worlds.first && self.worlds.first.rooms.first) ?
                self.worlds.first.rooms.first.guid : nil
          }
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
  
  def befriend(new_friend)
    redis_relationships.multi do
      redis_relationships.sadd "#{self.guid}:friends", new_friend.guid
      redis_relationships.sadd "#{new_friend.guid}:friends", self.guid
    end
    # send notification to current user
    self.send_message({
      :msg => 'friend_added',
      :data => {
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
        :user => {
          :guid => self.guid,
          :username => self.username
        }
      }
    })
    true
  end
  
  def unfriend(sworn_enemy)
    redis_relationships.multi do
      redis_relationships.srem "#{self.guid}:friends", sworn_enemy.guid
      redis_relationships.srem "#{sworn_enemy.guid}:friends", self.guid
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
    redis_relationships.sinter "#{self.guid}:friends", "#{user.guid}:friends"
  end

  def mutual_friends_with(user)
    User.find_all_by_guid(self.mutual_friend_guids_with(user), :order => 'username')
  end
  
  def is_mutual_friends_with?(user1, user2)
    user1.mutual_friend_guids_with(user2).include? self.guid
  end
  
  def is_friends_with?(user)
    redis_relationships.sismember "#{self.guid}:friends", user.guid
  end
  
  def friend_guids
    redis_relationships.smembers "#{self.guid}:friends"
  end
  
  def friends
    User.find_all_by_guid(self.friend_guids, :order => 'username')
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
    InteractivitySession.find_by_user_guid(self.guid)
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
    self.background_slots = 20
    self.avatar_slots = 20
    self.in_world_object_slots = 20
  end
  
  def unlink_friendships
    self.friend_guids.each do |friend_guid|
      redis_relationships.multi do
        redis_relationships.srem "#{self.guid}:friends", friend_guid
        redis_relationships.srem "#{friend_guid}:friends", self.guid
      end
    end
  end
end
