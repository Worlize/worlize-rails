class RedisModel
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Callbacks
  extend ActiveModel::Naming

  def self.attribute_list=(newValue)
    @attribute_list = newValue
  end

  def self.attribute_list
    @attribute_list ||= {}
  end
  
  def self.redis_server(newValue)
    @redis_server = newValue.to_s
  end
  
  def self.get_redis_server
    @redis_server
  end

  def self.redis_hash_key(newValue)
    @hash_key = newValue.to_s
  end
  
  def self.get_redis_hash_key
    @hash_key
  end

  def self.schema_version(newValue)
    @schema_version = newValue
  end
  
  def self.get_schema_version
    @schema_version
  end

  def self.initialize_attributes(*attrs)
    # Build accessors with hooks into ActiveModel::Dirty
    self.attribute_list = attrs
    self.attribute_list.each do |attribute|
      attribute_name = attribute.to_s
      define_method attribute_name, lambda { attributes[attribute_name] }
      define_method "#{attribute_name}=", lambda { |newvalue|
        self.send "#{attribute_name}_will_change!"
        attributes[attribute_name] = newvalue
      }
    end
    define_attribute_methods self.attribute_list
    define_model_callbacks :create, :update, :destroy
  end
  
  def attributes
    @attributes ||= Hash[*(self.class.attribute_list.map { |a| [a.to_s,nil] }.flatten)]
  end
  
  def set_attributes(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value) if self.class.attribute_list.include?(name.to_sym)
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
        redis.hdel self.class.get_redis_hash_key, guid
      end
      @destroyed = true
      freeze
      return self
    end
    false
  end
  
  def self.count
    redis.hlen self.get_redis_hash_key
  end
  
  def self.destroy_all
    guids = redis.hkeys self.get_redis_hash_key
    guids.each do |guid|
      object = self.find(guid)
      object.destroy unless object.nil?
    end
    true
  end
  
  def self.delete_all
    guids = redis.hkeys self.get_redis_hash_key
    redis.multi do 
      guids.each do |guid|
        redis.hdel self.get_redis_hash_key, guid
      end
    end
    true
  end
  
  def self.find_all
    guids = redis.hkeys self.get_redis_hash_key
    guids.map { |guid| self.find(guid) }.select { |obj| !obj.nil? }
  end
  
  def self.create(attributes = {})
    obj = self.new(attributes)
    obj.save
    obj
  end
  
  def self.find(guid)
    blob = redis.hget(self.get_redis_hash_key, guid)
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
  
  def self.redis
    @r ||= begin
      r = Redis.new(
        :host => Worlize.config['redis_servers'][self.get_redis_server]['host'] || 'localhost',
        :port => Worlize.config['redis_servers'][self.get_redis_server]['port'] || 6379
      )
      r.select Worlize.config['redis_servers'][self.get_redis_server]['db']
      r
    end
  end
  
  private

  def redis
    self.class.redis
  end

  def _actually_save
    return false unless valid?
    success = false
    begin
      hash = self.serializable_hash.merge({ "schema_version" => self.class.get_schema_version })
      redis.hset self.class.get_redis_hash_key, guid, Yajl::Encoder.encode(hash)
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

end