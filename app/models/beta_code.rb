class BetaCode < ActiveRecord::Base
  has_many :users
  
  after_create :initialize_usage_count
  before_destroy :delete_usage_count
  
  def consume
    redis.incr("beta_code:#{self.id}:usage_count")
  end
  
  def signups_used
    redis.get("beta_code:#{self.id}:usage_count").to_i
  end
  
  def signups_remaining
    self.signups_allotted - self.signups_used
  end
  
  def consumed?
    signups_remaining <= 0
  end
  
  private

  def initialize_usage_count
    redis.set("beta_code:#{self.id}:usage_count", 0)
  end
  
  def delete_usage_count
    redis.del("beta_code:#{self.id}:usage_count")
  end
  
  def redis
    Worlize::RedisConnectionPool.get_client(:currency)
  end
end
