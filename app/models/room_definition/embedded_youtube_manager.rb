class RoomDefinition::EmbeddedYoutubeManager
  attr_accessor :room_definition
  attr_accessor :raw_data

  def initialize(room_definition)
    self.room_definition = room_definition
    load
  end

  def load
    begin
      self.raw_data = Yajl::Parser.parse(redis.hget('embedded_youtube_players', room_definition.guid))
    rescue
      self.raw_data = []
    end
    self
  end
  
  def save
    redis.hset('embedded_youtube_players', room_definition.guid, Yajl::Encoder.encode(raw_data))
    self
  end
  
  def destroy
    redis.hdel('embedded_youtube_players', room_definition.guid)
  end

  def create_new_player
    # TODO: Put default video id into a config somewhere
    player = { 
               'guid' => Guid.new.to_s,
               'x' => 255,
               'y' => 110,
               'width' => 500,
               'height' => 281,
               'data' => {}
             }
    raw_data << player
    save
    Worlize::InteractServerManager.instance.broadcast_to_room(
      room_definition.guid,
      {
        :msg => 'youtube_player_added',
        :data => {
          :room => room_definition.guid,
          :player => player
        }
      }
    )
    player
  end
  
  def move_player(player_guid, x, y, width, height)
    raw_data.each do |player|
      if player['guid'] == player_guid
        player['x'] = x
        player['y'] = y
        player['width'] = width
        player['height'] = height
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'youtube_player_moved',
            :data => {
              :room => room_definition.guid,
              :player => player
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified embedded youtube player guid"
  end
  
  def update_player_data(player_guid, data)
    raw_data.each do |player|
      if player['guid'] == player_guid
        player['data'] = data
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'youtube_player_data_updated',
            :data => {
              :room => room_definition.guid,
              :player => player
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified embedded youtube player guid"
  end
  
  def remove_player(player_guid)
    # find instance in the list, remove it, and announce the change to the room
    raw_data.each_index do |i|
      if raw_data[i]['guid'] == player_guid
        raw_data.delete_at i
        save
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room_definition.guid,
          {
            :msg => 'youtube_player_removed',
            :data => {
              :room => room_definition.guid,
              :guid => player_guid
            }
          }
        )
        return true
      end
    end
    raise Exception, "Unable to find specified embedded youtube player guid"
    
  end

  def youtube_players
    raw_data
  end
  
  private
  
  def redis
    Worlize::RedisConnectionPool.get_client(:room_definitions)
  end
  
end