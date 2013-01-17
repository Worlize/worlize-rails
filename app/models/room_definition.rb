class RoomDefinition
  include HTTParty
  
  @@servers = Worlize.config['internal_api_servers']
  base_uri @@servers[@@servers.length*rand]

  headers 'Content-Type' => 'application/json'
  format :json

  attr_accessor :guid
  attr_accessor :name
  attr_accessor :background
  attr_accessor :world_guid
  attr_accessor :properties
  attr_accessor :items
  
  def self.find(guid)
    rd = RoomDefinition.new
    return rd.load(guid) ? rd : nil
  end
  
  def self.create(room)
    result = self.post(
      "/rooms/#{room.guid}/definition",
      :body => Yajl::Encoder.encode({
        :name => room.name,
        :worldGuid => room.world.guid,
        :ownerGuid => room.world.user.guid,
        :properties => {}
      })
    )
    code = result.response.code.to_i
    if code >= 200 && code <= 299
      if result.parsed_response && result.parsed_response['success']
        rd = RoomDefinition.new(room.guid)
        rd.update_data(result.parsed_response['room'])
        return rd
      end
    end
    return nil
  end
  
  def self.clone(sourceGuid, destGuid, roomGuidMap, itemGuidMap)
    result = self.post(
      "/rooms/#{sourceGuid}/clone",
      :body => Yajl::Encoder.encode({
        :destRoomGuid => destGuid,
        :roomGuidMap => roomGuidMap,
        :itemGuidMap => itemGuidMap
      })
    )
    code = result.response.code.to_i
    if code >= 200 && code <= 299
      if result.parsed_response && result.parsed_response['success']
        return true
      end
    end
    return false
  end

  def initialize(guid=nil)
    self.guid = guid
    self.properties = {}
    self.items = []
  end
  
  def load(guid)
    begin
      result = self.class.get("/rooms/#{guid}/definition")
      code = result.response.code.to_i
      if code >= 200 && code <= 299
        if result.parsed_response && result.parsed_response['success']
          update_data(result.parsed_response['room'])
          return true
        end
      end
    rescue
    end
    
    return false
  end
  
  def save
    begin
      result = self.class.put(
        "/rooms/#{self.guid}/definition",
        :body => Yajl::Encoder.encode({
          :name => self.name,
          :properties => self.properties
        })
      )
      code = result.response.code.to_i
      if code >= 200 && code <= 299
        if result.parsed_response && result.parsed_response['success']
          return true
        end
      end
    rescue
    end

    return result
  end
  
  def destroy
    result = self.class.delete("/rooms/#{self.guid}/definition")
    code = result.response.code.to_i
    if code >= 200 && code <= 299
      if result.parsed_response && result.parsed_response['success']
        return true
      end
    end
    
    return false
  end
  
  def remove_item(instance_guid)
    result = self.class.delete("/rooms/#{self.guid}/definition/items/#{instance_guid}")
    code = result.response.code.to_i
    if code >= 200 && code <= 299
      if result.parsed_response && result.parsed_response['success']
        return true
      end
    end
    return false
  end
  
  def update_data(data)
    self.guid = data['guid']
    self.name = data['name']
    self.background = data['background']
    self.world_guid = data['worldGuid']
    self.properties = data['properties']
    self.items = data['items']
  end
end