class PropsController < ApplicationController
  before_filter :require_user

  def show
    prop = Prop.find_by_guid(params[:id])
    if prop
      render :json => {
        :success => true,
        :data => prop.hash_for_api
      }
    else
      render :json => {
        :success => false,
        :description => "Unable to find the specified prop"
      }, :status => 404
    end
  end
  
  def send_as_gift
    prop = Prop.find_by_guid(params[:id])
    recipient = User.find_by_guid(params[:recipient_guid])
    
    if recipient.nil?
      render :json => {
        :success => false,
        :description => "Unable to find the specified recipient"
      } and return
    end

    if prop.nil?
      render :json => {
        :success => false,
        :description => "Unable to find the specified prop"
      } and return
    end

    gift = prop.gifts.build(:sender => current_user, :recipient => recipient, :note => params[:note])
    if gift.save
      Worlize.event_logger.info("action=gift_sent giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
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
  
  def save_to_locker
    @prop = Prop.find_by_guid(params[:id])

    if current_user.prop_slots <= current_user.prop_instances.count
      render :json => {
        :success => false,
        :description => "You do not have enough locker space to save this prop."
      } and return
    end
    
    if @prop.nil?
      render :json => {
        :success => false,
        :description => "Unable to find the specified prop."
      } and return
    end
    
    pi = current_user.prop_instances.create(:prop => @prop)
    if pi.persisted?
      render :json => {
        :success => true,
        :data => pi.hash_for_api
      }
    else
      render :json => {
        :success => false,
        :description => "Unable to create prop instance"
      }
    end
  end
  
end
