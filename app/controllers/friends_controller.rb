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
end
