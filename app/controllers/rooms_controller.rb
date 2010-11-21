class RoomsController < ApplicationController
  
  before_filter :require_user
  
  def index
    world = World.find_by_guid(params[:world_id])
    if world
      rooms = world.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => (rand * 15).round
        }
      end

      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => rooms
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "There is no such world."
      })
    end
  end
  
  def show
    room_definition = RoomDefinition.find(params[:id])
    
    if room_definition
      render :json => Yajl::Encoder.encode({
        :success => true,
        # make sure to include hotspots in the output
        :data => room_definition.serializable_hash.merge({'hotspots' => room_definition.hotspots})
      })
    else
      render :json => Yajl::Encoder.encode({ :success => false, :description => "Unable to load room" })
    end
    
  end
  
  def enter
    @room = Room.find_by_guid!(params[:id])
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
          render :json => { :success => true, :interactivity_session => s.serializable_hash }
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
      unless bi.nil?
        room.background_instance = bi
        room.room_definition.background = bi.background.image.url
      end
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
