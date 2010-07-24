class RoomsController < ApplicationController
  
  before_filter :require_user
  
  def show
    redis = Worlize::RedisConnectionPool.get_client(:room_definitions)
    room_definition_text = redis.hget 'roomDefinition', params[:id]

    if room_definition_text
      begin
        room_definition = Yajl::Parser.parse(room_definition_text)
        success = true
      rescue
        error_description = 'Unable to decode room definition'
        success = false
      end
    else
      error_description = 'Unable to locate room definition.'
      success = false
    end
    
    room_definition[:guid] = params[:id]

    if success
      render :json => Yajl::Encoder.encode({
        :success => success,
        :data => room_definition
      })
    else
      render :json => Yajl::Encoder.encode({ :success => false, :description => error_description })
    end
    
  end
  
  def enter
    if params[:id].length == 36
      @room = Room.find_by_guid(params[:id])
    else
      @room = Room.find(params[:id])
    end
    @user = current_user
    interact_server_id = Worlize::InteractServerManager.instance.server_for_room(@room.guid)
    s = current_user.interactivity_session || InteractivitySession.new
    respond_to do |format|
      if s.update_attributes(
          :username => @user.username,
          :user_guid => @user.guid,
          :room_guid => @room.guid,
          :world_guid => @room.world.guid,
          :server_id => interact_server_id
        )
        format.html do
          flash[:notice] = "Room #{@room.name} entered."
          redirect_to enter_world_url
        end
        format.json do
          render :json => { :success => true, :server_id => interact_server_id }
        end
      else
        format.html do
          flash[:notice] = "Unable to enter #{@room.name}."
          redirect_to admin_world_rooms_url(@room.world)
        end
        format.json { render :json => { :success => false } }
      end
    end
  end
  
  def create
    world = current_user.worlds.first
    room = world.rooms.new(:name => params[:name])
    if room.save
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => {
          :room_guid => room.guid
        }
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false
      })
    end
  end
  
  def update
    world = current_user.worlds.first
    room = world.rooms.find_by_guid(params[:id])
    
    render :json => Yajl::Encoder.encode({
      :success => false,
      :description => "Unable to locate specified room."
    }) unless room
    
    room.name = params[:name] if params[:name]
    
    if params[:background_instance_guid]
      bi = BackgroundInstance.find_by_guid(params[:background_instance_guid])
      room.background_instance = bi if bi
    end
    
    if room.save
      render :json => Yajl::Encoder.encode({
        :success => true
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false
      })
    end
  end

  def destroy
    world = current_user.worlds.first
    room = world.rooms.find_by_guid(params[:id])
    
    room.destroy if room

    render :json => Yajl::Encoder.encode({
      :success => room ? room.destroyed? : false
    })
  end
  
end
