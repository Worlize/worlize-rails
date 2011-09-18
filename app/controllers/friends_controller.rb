class FriendsController < ApplicationController
  before_filter :require_user

  # List friends
  def index
    if params[:user_id]
      user = User.find_by_guid(params[:user_id])
    else
      user = current_user
    end
    
    friends = user.friends.map do |friend|
      friend_data = {
        :username => friend.username,
        :guid => friend.guid,
        :online => friend.online?
      }
      if friend.worlds.first && friend.worlds.first.rooms.first
        friend_data[:world_entrance] = friend.worlds.first.rooms.first.guid
      end
      friend_data
    end
    
    output = {
      :success => true,
      :data => {
        :friends => friends
      }
    }
    
    if user == current_user
      output[:data][:pending_friends] = user.pending_friends.map do |friend|
        {
          :username => friend.username,
          :guid => friend.guid,
          :mutual_friends => friend.mutual_friends_with(current_user).map do |mutual_friend|
            {
              :guid => mutual_friend.guid,
              :username => mutual_friend.username
            }
          end
        }
      end
    end
    
    render :json => Yajl::Encoder.encode(output)
  end
  
  # Unfriend
  def destroy
    sworn_enemy = User.find_by_guid(params[:id])
    render :json => Yajl::Encoder.encode({
      :success => current_user.unfriend(sworn_enemy)
    })
  end
  
  # Find all facebook friends who are on worlize
  def facebook

    # Koala API methods will raise errors for things like expired tokens
    begin
      fb_graph = Koala::Facebook::API.new(params[:access_token])
      # Get user's list of facebook friends
      fb_friends = fb_graph.get_connections('me', 'friends', {'fields' => 'id,name,picture'})
    rescue Koala::Facebook::APIError => e
      render :json => {
        'success' => false,
        'error' => e.to_s
      } and return
    end
    
    fb_friends.sort! { |a,b| a['name'].downcase <=> b['name'].downcase }
      
    # Keep a reference to each by their Facbook ID so we can find and return
    # the facebook data once we find all the worlize users with matching
    # facebook IDs.
    fb_friends_by_id = Hash.new
    fb_friends.each do |fb_friend|
      fb_friends_by_id[fb_friend['id']] = fb_friend
    end
    
    # Find all Worlize users that have linked a facebook account with an ID
    # contained in the current user's Facebook friend list.
    matches = User.joins(:authentications).
                   where(:authentications => {
                      :provider => 'facebook',
                      :uid => fb_friends.map { |f| f['id'] }
                   });
    
    matches.find_each do |user|
      fb_authentication = user.authentications.where(:provider => 'facebook').first
      fb_friend = fb_friends_by_id[fb_authentication.uid]
      fb_friend['worlize'] = user.public_hash_for_api.merge({
        'is_friend' => user.is_friends_with?(current_user)
      })
    end
    
    on_worlize       = fb_friends.select { |f| f['worlize'] }
    not_on_worlize   = fb_friends.reject { |f| f['worlize'] }
    already_friended = on_worlize.select { |f| f['worlize']['is_friend'] }
    not_yet_friended = on_worlize.reject { |f| f['worlize']['is_friend'] }
    
    render :json => {
      'success' => true,
      'data' => {
        'not_yet_friended' => not_yet_friended,
        'already_friended' => already_friended,
        'not_on_worlize' => not_on_worlize
      }
    }
  end  
  
  def request_friendship
    potential_friend = User.find_by_guid(params[:id])
    if potential_friend == current_user
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You cannot add yourself as a friend!"
      }) and return 
    end
    
    render :json => Yajl::Encoder.encode({
      :success => current_user.request_friendship_of(potential_friend)
    })
  end
  
  def reject_friendship
    rejected_friend = User.find_by_guid(params[:id])
    render :nothing and return if rejected_friend == current_user
    
    render :json => Yajl::Encoder.encode({
      :success => current_user.reject_friendship_request_from(rejected_friend)
    })
  end
  
  def accept_friendship
    new_friend = User.find_by_guid(params[:id])
    render :nothing and return if new_friend == current_user
    
    render :json => Yajl::Encoder.encode({
      :success => current_user.accept_friendship_request_from(new_friend)
    })
  end
  
  def retract_friendship_request
    potential_friend = User.find_by_guid(params[:id])
    render :nothing and return if potential_friend == current_user
    
    render :json => Yajl::Encoder.encode({
      :success => current_user.retract_friendship_request_for(potential_friend)
    })
  end
  
  def invite_to_join
    friend = User.find_by_guid(params[:id])
    if friend.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "The specified user does not exist."
      }) and return
    end
    
    room = Room.find_by_guid(current_user.interactivity_session.room_guid)
    
    friend.send_message({
      :msg => "invitation_to_join_friend",
      :data => {
        :user => current_user.public_hash_for_api,
        :room_guid => current_user.interactivity_session.room_guid,
        :room_name => room.name,
        :world_name => room.world.name
      }
    })
    
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end
  
  def request_to_join
    friend = User.find_by_guid(params[:id])
    
    if friend.interactivity_session.room_guid == current_user.interactivity_session.room_guid
      render :json => Yajl::Encoder.encode({
        :success => true,
        :description => "You are already in the same room with the specified user."
      }) and return
    end
    
    if friend.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "The specified user does not exist."
      }) and return
    end
    
    friend.send_message({
      :msg => "request_permission_to_join",
      :data => {
        :user => current_user.public_hash_for_api,
        :invitation_token => params[:invitation_token]
      }
    })
    
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end
  
  def grant_permission_to_join
    friend = User.find_by_guid(params[:id])
    if friend.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "The specified user does not exist."
      }) and return
    end
    
    friend.send_message({
      :msg => "permission_to_join_granted",
      :data => {
        :user => current_user.public_hash_for_api,
        :room_guid => current_user.interactivity_session.room_guid,
        :invitation_token => params[:invitation_token]
      }
    })
    
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end
end
