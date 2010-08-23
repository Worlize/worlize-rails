class User < ActiveRecord::Base
  before_create :assign_guid
  after_create :initialize_currency
  
  has_many :worlds, :dependent => :destroy
  has_many :background_instances, :dependent => :nullify
  has_many :in_world_object_instances, :dependent => :nullify
  has_many :avatar_instances, :dependent => :nullify
  has_many :prop_instances, :dependent => :nullify
  
  has_many :avatars, :foreign_key => 'creator_id', :dependent => :nullify
  
  acts_as_authentic do |c|
    #config options here
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
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
  def initialize_currency
    redis = Worlize::RedisConnectionPool.get_client(:currency)
    redis.set "coins:#{self.guid}", Worlize.config['initial_currency']['coins'] || 0
    redis.set "bucks:#{self.guid}", Worlize.config['initial_currency']['bucks'] || 0
  end
  
end
