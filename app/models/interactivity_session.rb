class InteractivitySession
  #TODO: Abstract the basic functionality into a base class or mixin

  include ActiveModel::Conversion
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Callbacks
  extend ActiveModel::Naming

  @@attributes = [
                  :session_guid,
                  :user_guid,
                  :world_guid,
                  :room_guid,
                  :username,
                  :server_id,
                  :facebook_id
                 ]
  
  @@schema_version = 1

  define_attribute_methods @@attributes
  define_model_callbacks :create, :update, :destroy

  validates :user_guid, :presence => true
  validates :room_guid, :presence => true
  validates :world_guid, :presence => true

  before_create :assign_guid

  # Build accessors with hooks into ActiveModel::Dirty
  @@attributes.each do |attribute|
    attribute_name = attribute.to_s
    define_method attribute_name, lambda { attributes[attribute_name] }
    define_method "#{attribute_name}=", lambda { |newvalue|
      self.send "#{attribute_name}_will_change!"
      attributes[attribute_name] = newvalue
    }
  end

  alias :guid :session_guid
  alias :id :session_guid
  
  def attributes
    @attributes ||= Hash[*(@@attributes.map { |a| [a.to_s,nil] }.flatten)]
  end
  
  def set_attributes(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value) if @@attributes.include?(name.to_sym)
    end
  end
  
  def update_attributes(attributes = {})
    set_attributes(attributes)
    save
  end

  def initialize(attributes = {})
    @persisted = false
    set_attributes(attributes)
  end
  
  def persisted?
    @persisted
  end
  
  def destroyed?
    @destroyed ||= false
  end
  
  def save
    result = false
    if persisted?
      _run_update_callbacks do
        result = _actually_save
      end
    else
      _run_create_callbacks do
        result = _actually_save
      end
    end
    result
  end
  
  def destroy
    if persisted?
      _run_destroy_callbacks do
        redis.multi do
          redis.hdel "session", session_guid
          redis.srem "sessionIds", session_guid
          redis.hdel "sessionByUser", user_guid
          redis.hdel "userBySession", session_guid
        end
      end
      @destroyed = true
      freeze
      return self
    end
    false
  end
  
  def self.count
    redis.scard "sessionIds"
  end
  
  def self.destroy_all
    session_ids = redis.smembers "sessionIds"
    session_ids.each do |session_guid|
      session = self.find(session_guid)
      session.destroy unless session.nil?
    end
    true
  end
  
  def self.delete_all
    session_ids = redis.smembers "sessionIds"
    session_ids.each do |session_guid|
      user_guid = redis.hget "userBySession", session_guid
      redis.multi do 
        redis.hdel "sessionByUser", user_guid
        redis.hdel "userBySession", session_guid
        redis.hdel "session", session_guid
        redis.srem "sessionIds", session_guid
      end
    end
    true
  end
  
  def self.find_all
    session_ids = redis.smembers "sessionIds"
    session_ids.map { |sid| self.find(sid) }.select { |session| !session.nil? }
  end
  
  def self.create(attributes = {})
    obj = self.new(attributes)
    obj.save
    obj
  end
  
  def self.find(session_guid)
    blob = redis.hget("session", session_guid)
    unless blob.nil?
      begin
        data = Yajl::Parser.parse(blob)
      rescue
        return nil
      end
      session = self.new(data)
      session.send 'persisted=', true
      session.send '_set_clean'
      return session
    end
    nil
  end
  
  def self.find_by_user_guid(user_guid)
    session_guid = redis.hget 'sessionByUser', user_guid
    return self.find(session_guid) if session_guid
    nil
  end
  
  def self.redis
    Worlize::RedisConnectionPool.get_client('presence')
  end
  
  private

  def redis
    self.class.redis
  end

  def _actually_save
    return false unless valid?
    success = false
    begin
      old_session = redis.hget "sessionByUser", user_guid
      redis.multi do
        # If there's a stale session for this user, get rid of it
        if !old_session.nil? && old_session != session_guid
          redis.hdel "session", old_session
          redis.srem "sessionIds", old_session
        end
      
        hash = self.serializable_hash.merge({ "schema_version" => @@schema_version })
        redis.hset "session", session_guid, Yajl::Encoder.encode(hash)
        redis.hset "sessionByUser", user_guid, session_guid
        redis.hset "userBySession", session_guid, user_guid
        redis.sadd "sessionIds", session_guid
      end
      success = true
    rescue
      success = false
    end
    _set_clean
    @persisted ||= success
  end
  
  def persisted
    @persisted
  end
  
  def persisted=(newValue)
    @persisted = newValue
  end
  
  def _set_clean
    @previously_changed = changes
    @changed_attributes = {}
  end

  def assign_guid
    self.session_guid ||= Guid.new.to_s
  end
  
end