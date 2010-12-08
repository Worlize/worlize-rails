class User < ActiveRecord::Base
  before_create :assign_guid
  before_create :initialize_default_slots
  after_create :initialize_currency
  
  has_many :authentications
  
  has_many :worlds, :dependent => :destroy
  has_many :background_instances, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :avatar_instances, :dependent => :nullify
  has_many :prop_instances, :dependent => :nullify
  
  has_many :avatars, :foreign_key => 'creator_id', :dependent => :nullify
  
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :birthday, :timeliness => {
      :before => :thirteen_years_ago,
      :type => :date
  }
  validates :email, { :presence => true }
  
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
      :created_at => self.created_at,
      :admin => self.admin?,
      :state => self.state
    }
  end
  
  def hash_for_api
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
      :birthday => self.birthday
    )
  end

  def create_world
    world = self.worlds.create(:name => "#{self.username.capitalize}'s World")
    
    # Initialize user's first background instance
    bi = self.background_instances.create(:background => Background.first)
    
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
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    server_id = redis.get "interactServerForUser:#{self.guid}"
    return false if server_id.nil?
    redis.sismember "connectedUsers:#{server_id}", self.guid
  end
  
  def can_edit?(item)
    if item.respond_to? 'can_be_edited_by?'
      item.can_be_edited_by?(self)
    else
      false
    end
  end
  
  def coins
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.get("coins:#{self.guid}").to_i
  end
  
  def bucks
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.get("bucks:#{self.guid}").to_i
  end
  
  def debit_account(options)
    return false unless options
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    
    if options[:coins]
      currency_type = 'coins'
      amount = options[:coins]
    elsif options[:bucks]
      currency_type = 'bucks'
      amount = options[:bucks]
    else
      raise "You must specify either coins or bucks."
    end
    
    unless amount.kind_of? Integer
      raise "Amount must be an integer"
    end
    
    redis_key = "#{currency_type}:#{self.guid}"
    before = redis.get(redis_key).to_i
    
    if before - amount > 0
      after = redis.decrby(redis_key, amount).to_i
    else
      raise "Insufficient Funds"
    end

  end
  
  def credit_account(options)
    return false unless options
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    
    if options[:coins]
      currency_type = 'coins'
      amount = options[:coins]
    elsif options[:bucks]
      currency_type = 'bucks'
      amount = options[:bucks]
    else
      raise "You must specify either coins or bucks."
    end
    
    unless amount.kind_of? Integer
      raise "Amount must be an integer"
    end
    
    redis_key = "#{currency_type}:#{self.guid}"
    redis.incrby(redis_key, amount).to_i
  end

  def interactivity_session
    InteractivitySession.find_by_user_guid(self.guid)
  end
  
  def reset_appearance!
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    redis.del("userState:#{self.guid}")
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def initialize_currency
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.set "coins:#{self.guid}", Worlize.config['initial_currency']['coins'] || 0
    redis.set "bucks:#{self.guid}", Worlize.config['initial_currency']['bucks'] || 0
  end
  
  def initialize_default_slots
    self.prop_slots = 20
    self.background_slots = 20
    self.avatar_slots = 20
    self.in_world_object_slots = 20
  end
  
end
