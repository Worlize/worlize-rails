#!/usr/bin/env /Users/theturtle32/work/worlize/worlize-rails/script/rails runner

require 'pp'


unmodified_worlds = []
User.all.each do |u|
  world = u.worlds.first

  if world.rooms.length == 1
    if world.rooms.first.background_instance.background.guid == Background.initial_world_background_guid
      if r.room_definition.hotspots.length == 0
        if r.room_definition.
      unmodified_worlds.push(world)
    end
  end
  
end

unmodified_worlds.each do |w|
  puts w.name
end