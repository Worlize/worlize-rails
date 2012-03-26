class UpdateObjectDefinitions < ActiveRecord::Migration
  def self.up
    r = Worlize::RedisConnectionPool.get_client(:room_definitions)
    room_guids = r.hkeys('in_world_objects')
    room_guids.each do |guid|
      json = r.hget('in_world_objects', guid)
      begin
        data = Yajl::Parser.parse(json)
      rescue
      end
      
      if data.is_a? Array
        data.each do |obj|
          if obj['kind'].nil?
            obj['kind'] = 'image'
          end
        end
      end
      
      json = Yajl::Encoder.encode(data)
      r.hset('in_world_objects', guid, json)
    end
  end

  def self.down
    r = Worlize::RedisConnectionPool.get_client(:room_definitions)
    room_guids = r.hkeys('in_world_objects')
    room_guids.each do |guid|
      json = r.hget('in_world_objects', guid)
      begin
        data = Yajl::Parser.parse(json)
      rescue
      end
      
      if data.is_a? Array
        data.each do |obj|
          if obj['kind'] == 'image'
            obj.delete('kind')
          end
        end
      end
      
      json = Yajl::Encoder.encode(data)
      r.hset('in_world_objects', guid, json)
    end
  end
end
