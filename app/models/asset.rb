class Asset < RedisModel

  redis_server :assets
  redis_hash_key :asset
  schema_version 1

  initialize_attributes(
    :guid,
    :user_guid,
    :type,
    :s3_key,
    :s3_bucket,
    :mime_type,
    :url,
    :format
  )

  validates :guid, :presence => true
  validates :user_guid, :presence => true
  validates :type, :presence => true

  before_create :assign_guid

  alias :id :guid
  
  def assign_guid
    self.guid ||= Guid.new.to_s
  end
  
end