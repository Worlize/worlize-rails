class RoomsController < ApplicationController
  
  before_filter :require_user
  
  def index
    world = World.find_by_guid(params[:world_id])
    if world
      rooms = world.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => room.user_count
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
    room = Room.find_by_guid(params[:id])
    
    if room
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => room.hash_for_api(current_user)
      })
    else
      render :json => Yajl::Encoder.encode({ :success => false, :description => "Unable to load room" })
    end
    
  end
  
  def enter
    @room = Room.find_by_guid!(params[:id])
    @user = current_user
    interact_server_id = @room.interact_server_id
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
    world = World.find_by_guid(params[:world_id])
    if (world.user == current_user)
      room_name = params[:room_name] || 'Untitled Area'
      room = world.rooms.new(:name => room_name)
      if room.save
        render :json => Yajl::Encoder.encode({
          :success => true,
          :data => {
            :room_guid => room.guid
          }
        }) and return
      else
        error_message = room.errors.map { |k,v| "#{k} #{v}" }.join(", ")
      end
    else
      error_message = "Permission Denied"
    end
    render :json => Yajl::Encoder.encode({
      :success => false,
      :description => error_message
    })
  end
  
  def update
    room = Room.find_by_guid(params[:id])
    if room.world.user == current_user
      if room.update_attributes(:name => params[:room][:name])
        render :json => Yajl::Encoder.encode({
          :success => true
        }) and return
      else
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => room.errors.map { |k,v| "#{k} #{v}" }.join(', ')
        }) and return
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Permission Denied"
      }) and return
    end
  end

  def set_background
    success = false
    error = ""
    room = Room.find_by_guid!(params[:id])
    
    if current_user.can_edit? room
      updated_background_instances = []
      if params[:background_instance_guid]
        background_instance = BackgroundInstance.find_by_guid(params[:background_instance_guid])
        if background_instance.nil?
          error = "Unable to find the specified background instance."
        elsif !background_instance.room.nil?
          error = "Background already in use in another room."
        else
          old_background_instance = room.background_instance
          room.background_instance = background_instance
          room.room_definition.background = background_instance.background.image.url
          success = room.save
          if old_background_instance
            old_background_instance.room = nil
            updated_background_instances.push(old_background_instance.hash_for_api)
          end
          updated_background_instances.push(background_instance.hash_for_api)
          Worlize::InteractServerManager.instance.broadcast_to_room(room.guid, {
            :msg => 'room_definition_updated'
          })
        end
      end

      render :json => Yajl::Encoder.encode({
        :success => success,
        :data => {
          :updated_background_instances => updated_background_instances
        }
      })
      return
      
    else
      error = "Permission denied"
    end
    
    render :json => Yajl::Encoder.encode({
      :success => success,
      :description => error
    })
  end
  
  
  def destroy
    room = Room.find_by_guid!(params[:id])
    world = room.world
    description = ''
    if world.user == current_user
      room.destroy
      if room.destroyed?
        Worlize::InteractServerManager.instance.broadcast_to_room(room.guid, {
          :msg => 'goto_room',
          :data => world.rooms.first.guid
        })
      end
    else
      description = 'Permission denied'
    end
    render :json => Yajl::Encoder.encode({
      :success => room.destroyed?
    })
  end
  
end
