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
  
  
  def request_friendship
    potential_friend = User.find_by_guid(params[:id])
    render :nothing and return if potential_friend == current_user
    
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
