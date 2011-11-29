class RoomsController < ApplicationController
  
  before_filter :require_user
  
  def index
    world = World.find_by_guid(params[:world_id])
    if world
      rooms = world.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => room.user_count,
          :thumbnail => room.background_instance.background.image.thumb.url
        }
      end

      render :json => {
        :success => true,
        :data => rooms
      }
    else
      render :json => {
        :success => false,
        :description => "There is no such world."
      }
    end
  end
  
  # /rooms/directory
  def directory
    # Get list of active rooms
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    
    current_user_friend_guids = current_user.friend_guids
    current_user_facebook_friend_guids = current_user.facebook_friend_guids

    room_population = Hash.new

    active_room_guids_with_score = redis.zrangebyscore('activeRooms', '(0', '+inf', :withscores => true)
    active_room_guids_with_score.each_index do |index|
      if index % 2 == 0
        room_population[active_room_guids_with_score[index]] = active_room_guids_with_score[index+1].to_i
      end
    end
    
    room_info = []
    Room.where(:guid => room_population.keys).all.each do |room|
      
      # Check to see if any of our friends are in the room and include them
      # in the response if they are.
      friends_in_room = []
      friend_guids_in_room = room.connected_user_guids & current_user_friend_guids
      friend_guids_in_room.each do |user_guid|
        friend = User.find_by_guid(user_guid)
        if friend
          friend_info = friend.hash_for_friends_list('basic')
          if current_user_facebook_friend_guids.include?(friend.guid)
            friend_info[:friend_type] = 'facebook'
          end
          friends_in_room.push(friend_info)
        end
      end
      
      room_info.push({
        :room => room.basic_hash_for_api.merge(
          :user_count => room_population[room.guid],
          :thumbnail => room.background_instance ? room.background_instance.background.image.thumb.url : '/images/no-background-thumb.png'
        ),
        :world => room.world.basic_hash_for_api,
        :friends_in_room => friends_in_room
      })
    end
    
    # Throw in the public worlds' room entrances
    public_worlds = PublicWorld.all.each do |public_world|
      world = public_world.world
      entrance = world.rooms.first
      
      # If the room is already in the list, don't add a duplicate
      next unless room_population[entrance.guid].nil?
      
      # If we're adding the room this way, it's empty      
      room_info.push({
        :room => entrance.basic_hash_for_api.merge(
          :user_count => 0,  # entrance.user_count
          :thumbnail => entrance.background_instance ? entrance.background_instance.background.image.thumb.url : '/images/no-background-thumb.png'
        ),
        :world => world.basic_hash_for_api,
        :friends_in_room => []
      })
    end
    
    render :json => {
      :success => true,
      :data => {
        :rooms => room_info
      }
    }
  end
  
  def show
    room = Room.find_by_guid(params[:id])
    
    if room
      render :json => {
        :success => true,
        :data => room.hash_for_api(current_user)
      }
    else
      render :json => { :success => false, :description => "Unable to load room" }
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
        render :json => {
          :success => true,
          :data => {
            :room_guid => room.guid
          }
        } and return
      else
        error_message = room.errors.map { |k,v| "#{k} #{v}" }.join(", ")
      end
    else
      error_message = "Permission Denied"
    end
    render :json => {
      :success => false,
      :description => error_message
    }
  end
  
  def update
    room = Room.find_by_guid(params[:id])
    if room.world.user == current_user
      if room.update_attributes(:name => params[:room][:name])
        render :json => {
          :success => true
        } and return
      else
        render :json => {
          :success => false,
          :description => room.errors.map { |k,v| "#{k} #{v}" }.join(', ')
        } and return
      end
    else
      render :json => {
        :success => false,
        :description => "Permission Denied"
      } and return
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
        end
      end

      render :json => {
        :success => success,
        :data => {
          :updated_background_instances => updated_background_instances
        }
      }
      return
      
    else
      error = "Permission denied"
    end
    
    render :json => {
      :success => success,
      :description => error
    }
  end
  
  
  def destroy
    room = Room.find_by_guid!(params[:id])
    world = room.world
    description = ''
    if world.user == current_user
      if world.rooms.count == 1
        render :json => {
          :success => false,
          :description => "You cannot delete your last area.  You must create another area first."
        } and return
      end
      
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
    render :json => {
      :success => room.destroyed?
    }
  end
  
end
