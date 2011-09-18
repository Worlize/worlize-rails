class InWorld::HotspotsController < ApplicationController
  def create
    room = Room.find_by_guid(params[:room_id])
    
    if !current_user.can_edit?(room)
      render :json => {
        :success => false,
        :description => 'You do not have permission to author this room'
      } and return
    end

    begin
      if room
        
        redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
        
        if params[:data]
          data = Yajl::Decoder.decode(params[:data])
        else
          data = {}
        end
        
        hotspot = {
          'guid' => Guid.new.to_s
        }
        
        if data['x'] && data['x'].instance_of?(Fixnum)
          hotspot['x'] = data['x']
        else
          hotspot['x'] = 950/2
        end
        
        if data['y'] && data['y'].instance_of?(Fixnum)
          hotspot['y'] = data['y']
        else
          hotspot['y'] = 570/2
        end
        
        if data['points'] && data['points'].kind_of(Array)
          temp_pts = []
          data['points'].each do |point|
            if point[0].instance_of?(Fixnum) && point[1].instance_of?(Fixnum)
              tmp_pts.push(point)
            end
          end
          hotspot['points'] = tmp_pts
        else
          # Deafult points position
          hotspot['points'] = [ [-150,-100], [150,-100], [150,100], [-150,100] ]
        end
        
        if data['dest'] && data['dest'].instance_of?(String)
          hotspot['dest'] = data['dest']
        end
        
        if data['id'] && data['id'].instance_of?(String)
          hotspot['id'] = data['id']
        end
        
        existing_hotspots_json = redis.hget('hotspots', room.guid) || '[]'
        begin
          hotspots = Yajl::Parser.parse(existing_hotspots_json)
        rescue
          hotspots = []
        end
        hotspots.push(hotspot)
        redis.hset 'hotspots', room.guid, Yajl::Encoder.encode(hotspots)
        
        Worlize::PubSub.publish(
          "room:#{room.guid}",
          {
            :msg => 'new_hotspot',
            :room => room.guid,
            :data => hotspot
          }
        )
        success = true
        
      else
        success = false
        description = "Unable to find specified room"
      end
    rescue Exception => e
      success = false
      description = "Exception: " + e.to_s
    end
    
    if success
      render :json => {
        :success => true,
        :room_guid => room.guid,
        :data => hotspot
      }
    else
      render :json => {
        :success => false,
        :description => description
      }
    end
  end
  
  def update
    room_guid = params[:room_id]
    hotspot_guid = params[:id]
    
    room = Room.find_by_guid(room_guid)
    if room && current_user.can_edit?(room)
      redis = Worlize::RedisConnectionPool.get_client(:room_definitions)

      # Find the specified hotspot in the array
      hotspot = nil
      hotspots = room.room_definition.hotspots
      hotspots.each do |h|
        if h['guid'] == hotspot_guid
          hotspot = h
          break
        end
      end

      if hotspot
        # If we've found it, update it and re-pack and store the array
        
        # Updating position?
        if params[:x] && params[:y]
          hotspot['x'] = params[:x].to_i
          hotspot['y'] = params[:y].to_i
          if params[:points]
            begin
              points = Yajl::Parser.parse(params[:points])
              if points.instance_of?(Array) && points.length <= 50 && points.length > 2
                hotspot['points'] = points
              end
            rescue
            end
          end
          room.room_definition.hotspots = hotspots
          success = true
          Worlize::InteractServerManager.instance.broadcast_to_room(room.guid, {
            :msg => 'hotspot_moved',
            :data => {
              :guid => hotspot_guid,
              :x => hotspot['x'],
              :y => hotspot['y'],
              :points => hotspot['points']
            }
          })
          
        # Updating destination?
        elsif params[:dest]
          if params[:dest].length > 0
            dest_room = Room.find_by_guid(params[:dest])
            if dest_room
              hotspot['dest'] = dest_room.guid
              success = true
              room.room_definition.hotspots = hotspots
              broadcast_hotspot_dest_updated(room.guid, hotspot_guid, hotspot['dest'])
            else
              success = false
              description = "There is no such destination room"
            end
          else
            success = true
            hotspot.delete('dest')
            room.room_definition.hotspots = hotspots
            broadcast_hotspot_dest_updated(room.guid, hotspot_guid, nil)
          end
        end
        
      else
        success = false
        description = "Unable to find the specified hotspot in the room"
      end
      
    else
      success = false
      description = "Unable to find or edit specified room"
    end
    
    if success  
      render :json => {
        :success => true
      }
    else
      render :json => {
        :success => false,
        :description => description
      }
    end
  end
  
  def destroy
    room = Room.find_by_guid(params[:room_id])
    
    if !current_user.can_edit?(room)
      render :json => {
        :success => false,
        :description => 'You do not have permission to author this room'
      } and return
    end
    
    hotspot_guid = params[:id]
    if room
      rd = room.room_definition
      hotspots = rd.hotspots
      
      found_hotspot = false
      
      hotspots.each do |hotspot|
        if hotspot['guid'] == hotspot_guid
          found_hotspot = true
          break
        end
      end
      
      if found_hotspot
        rd.hotspots = rd.hotspots.select do |hotspot|
          hotspot['guid'] != hotspot_guid
        end
        
        Worlize::InteractServerManager.instance.broadcast_to_room(
          room.guid,
          {
            :msg => "hotspot_removed",
            :data => {
              :guid => hotspot_guid
            }
          }
        )
        
        render :json => {
          :success => true
        } and return
      end
    end
    
    render :json => {
      :success => false
    }
  end
  
  private
  
  def broadcast_hotspot_dest_updated(room_guid, hotspot_guid, dest)
    Worlize::InteractServerManager.instance.broadcast_to_room(
      room_guid,
      {
        :msg => "hotspot_dest_updated",
        :data => {
          :guid => hotspot_guid,
          :dest => dest
        }
      }
    )
  end
end
