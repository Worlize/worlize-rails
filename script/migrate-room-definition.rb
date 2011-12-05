redis = Worlize::RedisConnectionPool.get_client(:room_definitions)

errors = []

Room.all.each do |room|
  
  begin
    json = Yajl::Parser.parse(redis.hget('roomDefinition', room.guid))
  rescue
    errors.push("Unable to load definition for room #{room.guid}")
    next
  end
  
  begin
    hotspots = Yajl::Parser.parse(redis.hget('hotspots', room,guid))
  rescue
    hotspots = []
  end

  begin
    objs = Yajl::Parser.parse(redis.hget('in_world_objects', room.guid))
  rescue
    objs = []
  end

  begin
    youtube_players = Yajl::Parser.parse(redis.hget('embedded_youtube_players', room.guid))
  rescue
    youtube_players = []
  end

  json.delete('_sv_')
  json['_sv'] = 2

  json['owner'] = room.world.user.guid
  
  json['user_roles'] = {
    room.world.user.guid => [
      'admin'
    ]
  }
  
  json['background'] = {
    'instance_guid' => room.background_instance.guid,
    'guid' => room.background_instance.background.guid,
    'url' => room.background_instance.background.image.url
  }
  
  json['items'] = []
  
  objs.each do |obj|
    guid = obj.delete('guid')
    obj['type'] = 'image'
    obj['url'] = obj.delete('fullsize_url')
    instance = InWorldObjectInstance.find_by_guid(guid)
    item = {
      'type' => 'object',
      'guid' => guid,
      'object_guid' => instance.in_world_object.guid,
      'data' => obj
    }
    json['items'].push(item)
  end
  
  youtube_players.each do |player|
    guid = player.delete('guid')
    original_player_data = player.delete('data')
    player.merge!(original_player_data)
    item = {
      'type' => 'youtube_player',
      'guid' => guid,
      'data' => player
    }
    json['items'].push(item)
  end
  
  hotspots.each do |hotspot|
    guid = hotspot.delete('guid')
    item = {
      'type' => 'hotspot',
      'guid' => guid,
      'data' => hotspot
    }
    json['items'].push(item)
  end
  
  puts Yajl::Encoder.encode(json, :pretty => true, :indent => '  ')
  puts "\n\n"
  
  redis.hset("roomDefinitionV2", room.guid, Yajl::Encoder.encode(json))
end