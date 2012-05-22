class WorldsController < ApplicationController
  before_filter :require_user

  def set_permalink
    world = World.find_by_guid(params[:id])
    if world
      if !current_user.can_edit?(world)
        respond_to do |format|
          format.json do
            render :json => {
              :success => false,
              :error => {
                :message => "Permission denied.",
                :code => 0
              }
            }
          end
          format.html do
            redirect_to root_url
          end
        end
        return
      end
      
      if world.permalink
        world.permalink.link = params[:permalink]
      else
        world.permalink = Permalink.new(:link => params[:permalink])
      end
      successful = world.permalink.save
      if successful
        world.notify_users_of_changes
      end
      respond_to do |format|
        format.json do
          render :json => {
            :success => successful,
            :permalink => world.permalink.link,
            :message => world.permalink.errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render :json => {
            :success => false,
            :description => "There is no such world."
          }
        end
      end
    end
  end

  def show
    world = World.find_by_guid(params[:id])
    if world
      respond_to do |format|
        format.json do
          render :json => {
            :success => true,
            :data => world.hash_for_api(current_user)
          }
        end
        format.html do
          redirect_to enter_room_url(world.rooms.first.guid)
        end
      end
    else
      respond_to do |format|
        format.json do
          render :json => {
            :success => false,
            :description => "There is no such world."
          }
        end
        format.html do
          redirect_to root_url
        end
      end
    end
  end
  
  # Handle the "save" button on the world properties dialog
  def update
    begin
      data = Yajl::Parser.parse(params[:data])
      if Rails.env == 'development'
        require 'pp'
        pp data
      end
    rescue
      render :json => {
        :success => false,
        :error => {
          :message => "Unable to parse JSON data",
          :code => 0 # TODO: design a system for error codes
        }
      } and return
    end
    
    world = World.find_by_guid(params[:id])
    
    if world.nil?
      render :json => {
        :success => false,
        :error => {
          :message => "Unable to find the specified world.",
          :code => 0 # TODO: design a system for error codes
        }
      } and return
    end
    
    if !current_user.can_edit?(world)
      render :json => {
        :success => false,
        :error => {
          :message => "Permission denied.",
          :code => 0
        }
      } and return
    end
    
    errors = []
    
    # Update world name
    world.name = data['name']
    if !world.save
      render :json => {
        :success => false,
        :error => {
          :message => "Unable to save changes: " + errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n"),
          :code => 0
        }
      } and return
    end
    
    # Update room order
    data['rooms'].each_with_index do |roomData, index|
      query = Room.where(:guid => roomData['guid'])
      query.update_all(:position => index)
    end
    
    data['rooms'].each do |roomData|
      room = Room.find_by_guid(roomData['guid'])
      unless room.nil?
        room.name = roomData['name']
        room.hidden = roomData['hidden']
        if room.changed? && !room.save
          errors.push("Unable to update room name for room #{room.guid} to #{room['name']}")
        end
        rd = room.room_definition
        roomData['properties'].each do |key,value|
          rd.properties[key] = value
        end
        rd.save
      end
    end
    
    # Broadcast new room order
    Worlize::InteractServerManager.instance.broadcast_to_world(world.guid, {
      :msg => 'room_list',
      :data => {
        :world_guid => world.guid,
        :rooms => world.rooms.map { |room| room.basic_hash_for_api }
      }
    })
    
    render :json => {
      :success => errors.length == 0,
      :errors => errors
    }
  end
  
  def user_list
    world = World.find_by_guid(params[:id])
    if world
      render :json => {
        :success => true,
        :data => world.user_list
      }
    else
      render :json => {
        :success => false,
        :description => "There is no such world."
      }
    end
  end
  
end
