class FriendsController < ApplicationController
  before_filter :require_user

  # List friends
  def index
    user = current_user

    # For now we only support retrieving the current user's friends
    # if params[:user_id]
    #   user = User.find_by_guid(params[:user_id])
    # else
    #   user = current_user
    # end
    # 
    # if user.nil?
    #   render :json => {
    #     :success => false,
    #     :error => "Unable to find the specified user"
    #   } and return
    # end

    output = {
      :success => true,
      :data => {}
    }

    friends_by_guid = {}
    friends = output[:data][:friends] = []
    
    facebook_friend_guids = current_user.facebook_friend_guids
    
    # List of auto-synced friend guids to drive the auto_synced property
    autosynced_friend_guids = facebook_friend_guids
    
    # Load Worlize Friends
    user.friends.each do |friend|
      friend_data = friend.hash_for_friends_list
      friends_by_guid[friend.guid] = friend_data
      friends.push(friend_data)
      if facebook_friend_guids.include?(friend.guid)
        friend_data[:friend_type] = 'facebook'
      end
    end
    
    # Load Facebook Friends
#     if user == current_user
#       if (params[:access_token] && !user.facebook_authentication.nil? &&
#           user.facebook_authentication.uid == params[:facebook_user_id])
#         # Loads all facebook friends, both on worlize and otherwise
#         fb_friends = load_facebook_friends(params[:access_token])

#         # Grab list of friend guids that we aren't supposed to automatically
#         # sync in from Facebook.
#         nosync_friend_guids = current_user.nosync_friend_guids
        
#         # Filter to friends that are on Worlize
#         on_worlize = fb_friends.select { |f| f.has_key?('worlize_user') }

#         on_worlize.each do |fb_data|
#           friend = fb_data['worlize_user']
          
#           fb_cached_data_changed = false
          
#           # Update cached Facebook data in the database
#           friend.facebook_authentication.profile_picture = fb_data['picture']
#           friend.facebook_authentication.display_name = fb_data['name']
#           friend.facebook_authentication.profile_url = fb_data['link']
          
#           if friend.facebook_authentication.changed?
#             friend.facebook_authentication.save(:validate => false)
#             fb_cached_data_changed = true
#           end
          
          
#           # Existing friend.  Proceed to fill in Facebook info
#           if friends_by_guid.has_key? friend.guid
#             Rails.logger.debug("Existing friend: #{friend.username}")
#             friend_data = friends_by_guid[friend.guid]
#             if fb_cached_data_changed
#               # Merge updated facebook data into existing hash
#               friend_data.merge! friend.hash_for_friends_list
#             end
#           else
            
#             # User isn't already friends with this user, befriend them.
#             # If the user explicitly removed this friend previously, don't
#             # auto-add them again.  Also, If the other user explicitly
#             # removed the current user, don't auto-add them.
#             if nosync_friend_guids.include?(friend.guid) || friend.nosync_friend?(current_user)
#               Rails.logger.debug("Skipping #{friend.username} due to nosync")
#               next
#             end

#             # add facebook friend without sending a live notification
#             # If there's a problem adding them, just skip and move on.
#             next unless current_user.befriend(friend,
#                                               :facebook_friend => true,
#                                               :send_notification => false)

#             friend_data = friends_by_guid[friend.guid] = friend.hash_for_friends_list
#             autosynced_friend_guids.push(friend.guid)
#             friends.push(friend_data)
            
#             # Send notification to new user of the friendship so that the
#             # current user will show up in their friends list right away
#             fb_profile = my_facebook_profile(params[:access_token])
#             my_friend_data = current_user.hash_for_friends_list
#             my_friend_data[:friend_type] = 'facebook'
#             my_friend_data[:auto_synced] = true
#             friend.send_message({
#               :msg => 'friend_request_accepted',
#               :data => {
#                 :user => my_friend_data
#               }
#             })
            
#             Rails.logger.debug("Added facebook friend #{friend.username}")
#           end
          
#           # Fill in friend data with extra information from Facebook.
#           friend_data[:friend_type] = 'facebook'
#           friend_data[:auto_synced] = autosynced_friend_guids.include?(friend.guid)
#         end
        
#         # Remove any automatically added friends that are no longer facebook
#         # friends.
#         new_list_of_facebook_friend_guids = on_worlize.map { |f| f['worlize_user'].guid }
#         current_user.facebook_friend_guids.each do |guid|
#           if !new_list_of_facebook_friend_guids.include?(guid)
#             current_user.unfriend(guid, :prevent_add_on_next_sync => false)
#           end
#         end
        
#         # Grab list of online Facebook friends to suggest that the user invite
#         online_facebook_friends = fb_friends.select do |f|
#           !f.has_key?('worlize_user') && f['fb_online_presence'] == 'active'
#         end
#         output[:data][:online_facebook_friends] = online_facebook_friends
#       end
#     end
    
    if user == current_user
      output[:data][:pending_friends] = user.pending_friends.map do |friend|
        {
          :username => friend.username,
          :guid => friend.guid,
          :picture => "#{request.scheme}://#{request.host_with_port}/images/unknown_user.png"
        }
      end
    end
    
    render :json => output
  end

  # Unfriend
  def destroy
    sworn_enemy = User.find_by_guid(params[:id])
    # Second parameter to unfriend() is true to indicate that
    # this person shouldn't be automatically re-added while syncing
    # Facebook friends, since they were explicitly removed.
    friend_removed = current_user.unfriend(sworn_enemy)
    render :json => {
      :success => true,
      :friend_removed => friend_removed
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
    
    result = {}
    result[:success] = current_user.reject_friendship_request_from(rejected_friend),
    if result[:success]
      result[:friend_guid] = rejected_friend.guid
    else
      result[:friend_guid] = params[:id]
    end
    
    render :json => result
  end
  
  def accept_friendship
    new_friend = User.find_by_guid(params[:id])
    render :nothing and return if new_friend == current_user
    
    result = {}
    if current_user.accept_friendship_request_from(new_friend, "#{request.scheme}://#{request.host_with_port}")
      result[:success] = true
    else
      result[:success] = false
    end
    
    if result[:success]
      result[:friends_list_entry] = new_friend.hash_for_friends_list
    end
    render :json => result
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
  
  def my_facebook_profile(access_token)
    return @my_facebook_profile if @my_facebook_profile
    fb_api = Koala::Facebook::API.new(access_token)
    return @my_facebook_profile = fb_api.get_object('me', {'fields' => 'id,name,link,picture'})
  end
  
  def load_facebook_friends(access_token)
    # Koala API methods will raise errors for things like expired tokens
    # We probably actually want that for now.
    fb_api = Koala::Facebook::API.new(access_token)
    # Get user's list of facebook friends
    
    # via Graph API
    # fb_friends = fb_api.get_connections('me', 'friends', {'fields' => 'id,name,picture'})
    
    # via FQL - allows access to the 'online_presence' field!
    query = 'SELECT uid, name, pic_square, online_presence, profile_url ' +
            'FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) ' +
            'ORDER BY uid'
    fb_friends = fb_api.fql_query(query)

    # we sort on the client side so this is unnecessary
    # fb_friends.sort! { |a,b| a['name'].downcase <=> b['name'].downcase }
      
    # Keep a reference to each by their Facebook ID so we can find and return
    # the facebook data once we find all the worlize users with matching
    # facebook IDs.
    fb_friends_by_id = Hash.new
    fb_friends.each do |fb_friend|
      # Also take the opportunity to normalize the FQL data field names
      # to their Graph API equivalents.
      if fb_friend.has_key?('uid')
        fb_friend['id'] = fb_friend['uid'].to_s
        fb_friend.delete('uid')
      end
      if fb_friend.has_key?('pic_square')
        fb_friend['picture'] = fb_friend['pic_square']
        fb_friend.delete('pic_square')
      end
      if fb_friend.has_key?('online_presence')
        fb_friend['fb_online_presence'] = fb_friend['online_presence']
        fb_friend.delete('online_presence')
      end
      if fb_friend.has_key?('profile_url')
        fb_friend['link'] = fb_friend['profile_url']
        fb_friend.delete('profile_url')
      end
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
    
    matches.all.each do |user|
      fb_authentication = user.facebook_authentication
      fb_friend = fb_friends_by_id[fb_authentication.uid]
      fb_friend['worlize_user'] = user
    end
    
    fb_friends
  end
end
