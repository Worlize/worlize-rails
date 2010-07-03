class RoomDefinition < RedisModel

  redis_server :room_definitions
  redis_hash_key :roomDefinition
  schema_version 1

  initialize_attributes(
    :guid,
    :world_guid,
    :name,
    :background_asset
  )

  validates :guid, :presence => true
  validates :world_guid, :presence => true
  validates :background_asset, :presence => true

  before_create :assign_guid
  
  alias :id :guid
  
  private

  def assign_guid
    self.guid ||= Guid.new.to_s
  end
  
end