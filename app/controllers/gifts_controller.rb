class GiftsController < ApplicationController

  def index
    gifts = current_user.received_gifts.order('created_at DESC')
    
    render :json => {
      :success => true,
      :data => gifts.map { |gift| gift.hash_for_api }
    }
  end
  
  # Ignore gift
  def destroy
    gift = current_user.received_gifts.find_by_guid(params[:id])
    if gift.nil?
      render :json => {
        :success => false,
        :description => 'Unable to find the specified gift id'
      } and return
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
    
    render :json => {
      :success => true
    }
  end
  
  def accept
    gift = current_user.received_gifts.find_by_guid(params[:id])
    if gift.nil?
      render :json => {
        :success => false,
        :description => 'Unable to find the specified gift id'
      } and return
    end
    
    # FIXME: Re-architect so that this isn't specific to the
    #        type of gift involved
    if gift.giftable_type == 'Avatar'
      
      # Check for available slots..
      if (current_user.avatar_instances.count >= current_user.avatar_slots)
        render :json => {
          :success => false,
          :description => "You don't have enough empty slots in your avatar locker.  You must buy more slots or delete an avatar before you can accept this gift."
        } and return
      end
      
      avatar = gift.giftable
      avatar_instance = current_user.avatar_instances.create(
        :avatar => avatar,
        :gifter => gift.sender
      )
      if avatar_instance.persisted?
        gift.destroy
        render :json => {
          :success => true,
          :data => avatar_instance.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "An unknown error occurred while accepting your gift."
        }
      end
    elsif gift.giftable_type == 'Background'
      
      # Check for available slots..
      if (current_user.background_instances.count >= current_user.background_slots)
        render :json => {
          :success => false,
          :description => "You don't have enough empty slots in your backgrounds locker.  You must buy more slots or delete a background before you can accept this gift."
        } and return
      end
      
      background = gift.giftable
      background_instance = current_user.background_instances.create(
        :background => background,
        :gifter => gift.sender
      )
      if background_instance.persisted?
        gift.destroy
        render :json => {
          :success => true,
          :data => background_instance.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "An unknown error occurred while accepting your gift."
        }
      end
    elsif gift.giftable_type == 'InWorldObject'
      
      # Check for available slots..
      if (current_user.in_world_object_instances.count >= current_user.in_world_object_slots)
        render :json => {
          :success => false,
          :description => "You don't have enough empty slots in your objects locker.  You must buy more slots or delete an object before you can accept this gift."
        } and return
      end
      
      in_world_object = gift.giftable
      object_instance = current_user.in_world_object_instances.create(
        :in_world_object => in_world_object,
        :gifter => gift.sender
      )
      if object_instance.persisted?
        gift.destroy
        render :json => {
          :success => true,
          :data => object_instance.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "An unknown error occurred while accepting your gift."
        }
      end
    else
      render :json => {
        :success => false,
        :description => "Gifts of type #{gift.giftable_type} are not yet supported."
      }
    end
    
  end
  
end
