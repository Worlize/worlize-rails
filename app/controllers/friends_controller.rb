class FriendsController < ApplicationController
  before_filter :require_user

  # List friends
  def index
    if params[:user_id]
      user = User.find_by_guid(params[:user_id])
    else
      user = current_user
    end
    
    if user.nil?
      render :json => {
        :success => false,
        :error => "Unable to find the specified user"
      } and return
    end

    output = {
      :success => true,
      :data => {}
    }
    
    friends_by_guid = {}
    friends = []
    
    # Load Facebook Friends
    if user == current_user
      if params[:access_token]
        fb_friends = load_facebook_friends(params[:access_token])

        on_worlize = fb_friends.select { |f| f['worlize_user'] }
        on_worlize.each do |data|
          friend = data['worlize_user']
          is_worlize_friend = friend.is_friends_with?(current_user)
          friend_data = {
            :friend_type => 'facebook',
            :name => data['name'], # Name from Facebook
            :picture => data['picture'],
            :username => friend.username,
            :guid => friend.guid,
            :online => friend.online?,
            :is_worlize_friend => is_worlize_friend,
            :facebook_id => data['id']
          }
          if friend.facebook_authentication
            friend_data[:facebook_profile] = friend.facebook_authentication.profile_url || "http://www.facebook.com/#{friend.facebook_authentication.uid}"
          end
          if friend.twitter_authentication && friend.twitter_authentication.profile_url
            friend_data[:twitter_profile] = friend.twitter_authentication.profile_url
          end
          if friend.worlds.first && friend.worlds.first.rooms.first
            friend_data[:world_entrance] = friend.worlds.first.rooms.first.guid
          end
          if friend.online?
            friend_data[:current_room_guid] = friend.current_room_guid
          end
          friends_by_guid[friend.guid] = friend_data
          friends.push(friend_data)
        end
      end
    end
    
    # Load Worlize Friends
    user.friends.each do |friend|
      next if friends_by_guid[friend.guid]
      friend_data = {
        :friend_type => 'worlize',
        :username => friend.username,
        :guid => friend.guid,
        :online => friend.online?,
        :picture => "#{request.scheme}://#{request.host_with_port}/images/unknown_user.png"
      }
      if friend.facebook_authentication
        friend_data[:facebook_profile] = friend.facebook_authentication.profile_url || "http://www.facebook.com/#{friend.facebook_authentication.uid}"
      end
      if friend.twitter_authentication && friend.twitter_authentication.profile_url
        friend_data[:twitter_profile] = friend.twitter_authentication.profile_url
      end
      if friend.worlds.first && friend.worlds.first.rooms.first
        friend_data[:world_entrance] = friend.worlds.first.rooms.first.guid
      end
      if friend.online?
        friend_data[:current_room_guid] = friend.current_room_guid
      end
      friends_by_guid[friend.guid] = friend_data
      friends.push(friend_data)
    end
    
    output[:data][:friends] = friends
    
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
    
    render :json => output
  end
  
  # Unfriend
  def destroy
    sworn_enemy = User.find_by_guid(params[:id])
    render :json => {
      :success => current_user.unfriend(sworn_enemy)
    }
  end
  
  # Find all facebook friends who are on worlize
  def facebook
    fb_friends = load_facebook_friends(params[:access_token])
    
    not_on_worlize   = fb_friends.reject { |f| f['worlize_user'] }
    on_worlize       = fb_friends.select { |f| f['worlize_user'] }

    on_worlize.each do |data|
      user = data['worlize_user']
      data.delete('worlize_user')
      data['worlize'] = user.public_hash_for_api.merge({
        'is_friend' => user.is_friends_with?(current_user)
      })
    end
    
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
      render :json => {
        :success => false,
        :description => "You cannot add yourself as a friend!"
      } and return 
    end
    
    render :json => {
      :success => current_user.request_friendship_of(potential_friend)
    }
  end
  
  def reject_friendship
    rejected_friend = User.find_by_guid(params[:id])
    render :nothing and return if rejected_friend == current_user
    
    render :json => {
      :success => current_user.reject_friendship_request_from(rejected_friend)
    }
  end
  
  def accept_friendship
    new_friend = User.find_by_guid(params[:id])
    render :nothing and return if new_friend == current_user
    
    render :json => {
      :success => current_user.accept_friendship_request_from(new_friend, "#{request.scheme}://#{request.host_with_port}")
    }
  end
  
  def retract_friendship_request
    potential_friend = User.find_by_guid(params[:id])
    render :nothing and return if potential_friend == current_user
    
    render :json => {
      :success => current_user.retract_friendship_request_for(potential_friend)
    }
  end
  
  def invite_to_join
    friend = User.find_by_guid(params[:id])
    if friend.nil?
      render :json => {
        :success => false,
        :description => "The specified user does not exist."
      } and return
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
    
    render :json => {
      :success => true
    }
  end
  
  def request_to_join
    friend = User.find_by_guid(params[:id])
    
    if friend.interactivity_session.room_guid == current_user.interactivity_session.room_guid
      render :json => {
        :success => true,
        :description => "You are already in the same room with the specified user."
      } and return
    end
    
    if friend.nil?
      render :json => {
        :success => false,
        :description => "The specified user does not exist."
      } and return
    end
    
    friend.send_message({
      :msg => "request_permission_to_join",
      :data => {
        :user => current_user.public_hash_for_api,
        :invitation_token => params[:invitation_token]
      }
    })
    
    render :json => {
      :success => true
    }
  end
  
  def grant_permission_to_join
    friend = User.find_by_guid(params[:id])
    if friend.nil?
      render :json => {
        :success => false,
        :description => "The specified user does not exist."
      } and return
    end
    
    friend.send_message({
      :msg => "permission_to_join_granted",
      :data => {
        :user => current_user.public_hash_for_api,
        :room_guid => current_user.current_room_guid,
        :invitation_token => params[:invitation_token]
      }
    })
    
    render :json => {
      :success => true
    }
  end
  
  private
  
  def load_facebook_friends(access_token)
    # Koala API methods will raise errors for things like expired tokens
    begin
      fb_graph = Koala::Facebook::API.new(access_token)
      # Get user's list of facebook friends
      fb_friends = fb_graph.get_connections('me', 'friends', {'fields' => 'id,name,picture'})
    rescue Koala::Facebook::APIError => e
      return []
    end
    
    fb_friends.sort! { |a,b| a['name'].downcase <=> b['name'].downcase }
      
    # Keep a reference to each by their Facebook ID so we can find and return
    # the facebook data once we find all the worlize users with matching
    # facebook IDs.
    fb_friends_by_id = Hash.new
    fb_friends.each do |fb_friend|
      fb_friends_by_id[fb_friend['id']] = fb_friend
    end
    
    # Find all Worlize users that have linked a facebook account with an ID
    # contained in the current user's Facebook friend list.
    matches = User.joins(:authentications).
                   includes(:authentications).
                   where(:authentications => {
                      :provider => 'facebook',
                      :uid => fb_friends.map { |f| f['id'] }
                   });
    
    matches.find_each do |user|
      fb_authentication = user.authentications.select { |a| a.provider == 'facebook' }.first
      fb_friend = fb_friends_by_id[fb_authentication.uid]
      fb_friend['worlize_user'] = user
    end
    
    fb_friends
  end
end
