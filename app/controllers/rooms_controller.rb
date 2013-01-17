class RoomsController < ApplicationController
  
  before_filter :require_user
  skip_before_filter :verify_authenticity_token, :only => [:enter]
  
  def index
    world = World.find_by_guid(params[:world_id])
    if world
      rooms = world.rooms.map do |room|
        room.basic_hash_for_api
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

    redis.zrangebyscore('activeRooms', '(0', '+inf', :withscores => true).each do |pair|
      room_population[pair[0]] = pair[1].to_i
    end
    
    room_info = []
    Room.where(:guid => room_population.keys).all.each do |room|

      next if room.hidden? || room.no_direct_entry? || room.moderators_only?
      
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
    if params[:id] == 'home'
      # special case for going to a user's home world entrance
      @room = current_user.worlds.first.rooms.first
    else
      @room = Room.find_by_guid!(params[:id])
    end
    
    if @room.locked? && !@room.world.user_is_moderator?(current_user)
      respond_to do |format|
        format.html do
          redirect_to enter_world_url
        end
        format.json do
          render :json => {
            :success => false,
            :failure_reason => 'room_locked',
            :message => "Sorry, the room is locked."
          }
        end
      end
      return
    end
    
    if @room.no_direct_entry && params[:using_hotspot] != 'true' && !@room.world.user_is_moderator?(current_user)
      respond_to do |format|
        format.html do
          redirect_to enter_world_url
        end
        format.json do
          render :json => {
            :success => false,
            :failure_reason => 'no_direct_entry',
            :message => "Sorry, you must go through a door to access that room."
          }          
        end
      end
      return
    end
    
    if @room.moderators_only? && !@room.world.user_is_moderator?(current_user)
      respond_to do |format|
        format.html do
          redirect_to enter_world_url
        end
        format.json do
          render :json => {
            :success => false,
            :failure_reason => 'moderators_only',
            :message => "Sorry, only moderators can enter that room."
          }
        end
      end
      return
    end
    
    # Is the room full?
    if !@room.world.user_is_moderator?(current_user) && @room.full?
      no_substitutes = params.include?(:no_substitues)
      world = @room.world
      requested_room = @room
      
      # Unless requested otherwise, send them to the next room in the list
      if no_substitutes || !@room.allow_cascade_when_full?
        error_message = "Sorry, the room is full."
      else
        error_message = "Sorry, the room is full and there were no alternatives."
        found_requested_room = false
        world.rooms.each do |room|
          unless found_requested_room
            found_requested_room = true if room.id == @room.id
            next
          end
        
          unless room.moderators_only? || room.full?
            @room = room
            break
          end
        end
      end
      
      # If we couldn't find another room to send the user to,
      # we will fail.
      if @room == requested_room
        respond_to do |format|
          format.html do
            redirect_to enter_world_url
          end
          format.json do
            render :json => {
              :success => false,
              :failure_reason => 'room_full',
              :message => error_message
            }
          end
        end
        return
      end
    end
    
    @user = current_user
    interact_server_id = @room.interact_server_id
    s = current_user.interactivity_session
    respond_to do |format|
      if s.update_attributes(
          :username => @user.username,
          :user_guid => @user.guid,
          :room_guid => @room.guid,
          :world_guid => @room.world.guid,
          :server_id => interact_server_id,
          :facebook_id => @user.facebook_authentication.nil? ? nil : @user.facebook_authentication.uid
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
        format.json do
          render :json => {
            :success => false,
            :failure_reason => 'unknown',
            :message => 'There was an error while trying to enter the requested room.'
          }
        end
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
            :room => room.basic_hash_for_api
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
  
  def destroy
    room = Room.find_by_guid!(params[:id])
    world = room.world
    room_owner = world.user
    description = ''
    if room_owner == current_user
      if world.rooms.count == 1
        render :json => {
          :success => false,
          :description => "You cannot delete your last area.  You must create another area first."
        } and return
      end
      
      background_instance = room.background_instance
      room.destroy
      if room.destroyed?
        if !background_instance.nil?
          background_instance = BackgroundInstance.find_by_guid(background_instance.guid)
          room_owner.send_message({
            :msg => 'background_instance_updated',
            :data => background_instance.reload.hash_for_api
          })
        end
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
