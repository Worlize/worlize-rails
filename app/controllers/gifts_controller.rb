class GiftsController < ApplicationController

  def index
    gifts = current_user.received_gifts
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :data => gifts.map { |gift| gift.hash_for_api }
    })
  end
  
  # Ignore gift
  def destroy
    gift = current_user.received_gifts.find(params[:id])
    if gift.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => 'Unable to find the specified gift id'
      }) and return
    end
    
    # If this is the last gift remaining for an avatar that has no
    # instances left, delete the actual avatar.
    # FIXME: Re-architect so that this isn't specific to the
    #        type of gift involved
    if gift.giftable_type == 'Avatar'
      avatar = gift.giftable
      instances_remaining = avatar.avatar_instances.count
      gifts_remaining = avatar.gifts.count
      if instances_remaining == 0 && gifts_remaining == 1
        avatar.destroy
      else
        gift.destroy
      end
    else
      gift.destroy
    end
    
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end
  
  def accept
    gift = current_user.received_gifts.find(params[:id])
    if gift.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => 'Unable to find the specified gift id'
      }) and return
    end
    
    # FIXME: Re-architect so that this isn't specific to the
    #        type of gift involved
    if gift.giftable_type == 'Avatar'
      avatar = gift.giftable
      avatar_instance = current_user.avatar_instances.create(:avatar => avatar)
      if avatar_instance.persisted?
        gift.destroy
        render :json => Yajl::Encoder.encode({
          :success => true
        })
      else
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "An unknown error occurred while accepting your gift."
        })
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Gifts of type #{gift.giftable_type} are not yet supported."
      })
    end
    
  end
  
end
