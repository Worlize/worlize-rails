class AvatarsController < ApplicationController
  before_filter :require_user

  def show
    avatar = Avatar.find_by_guid(params[:id])
    if avatar
      render :json => {
        :success => true,
        :data => avatar.hash_for_api
      }
    else
      render :json => {
        :success => false,
        :description => "Unable to find the specified avatar"
      }, :status => 404
    end
  end
  
  def send_as_gift
    avatar = Avatar.find_by_guid(params[:id])
    recipient = User.find_by_guid(params[:recipient_guid])
    
    if recipient.nil? || !current_user.is_friends_with?(recipient)
      render :json => {
        :success => false,
        :description => "You are not friends with the specified recipient"
      } and return
    end

    if avatar.nil?
      render :json => {
        :success => false,
        :description => "Unable to find the specified avatar"
      } and return
    end

    gift = avatar.gifts.build(:sender => current_user, :recipient => recipient, :note => params[:note])
    if gift.save
      render :json => {
        :success => true
      }
    else
      render :json => {
        :success => false,
        :description => errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
      }
    end
        
  end
end
