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
    
    # If this is the last gift remaining for an item that has no
    # instances left, delete the actual item.
    # FIXME: Re-architect so that this isn't specific to the
    #        type of gift involved
    if gift.giftable_type == 'Avatar'
      avatar = gift.giftable
      instances_remaining = avatar.avatar_instances.count
      gifts_remaining = avatar.gifts.count
      if instances_remaining == 0 && gifts_remaining == 1 && avatar.marketplace_item.nil?
        avatar.destroy
      else
        gift.destroy
      end
    elsif gift.giftable_type == 'Background'
      background = gift.giftable
      instances_remaining = background.background_instances.count
      gifts_remaining = background.gifts.count
      if instances_remaining == 0 && gifts_remaining == 1 && background.marketplace_item.nil?
        background.destroy
      else
        gift.destroy
      end
    elsif gift.giftable_type == 'InWorldObject'
      in_world_object = gift.giftable
      instances_remaining = in_world_object.in_world_object_instances.count
      gifts_remaining = in_world_object.gifts.count
      if instances_remaining == 0 && gifts_remaining == 1 && in_world_object.marketplace_item.nil?
        in_world_object.destroy
      else
        gift.destroy
      end
    else
      gift.destroy
    end
    
    Worlize.event_logger.info("action=gift_ignored giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
    
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
        Worlize.event_logger.info("action=gift_accepted giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
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
        Worlize.event_logger.info("action=gift_accepted giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
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
        Worlize.event_logger.info("action=gift_accepted giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
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
    elsif gift.giftable_type == 'Prop'
      
      # Check for available slots..
      if (current_user.prop_instances.count >= current_user.prop_slots)
        render :json => {
          :success => false,
          :description => "You don't have enough empty slots in your props locker.  You must buy more slots or delete a prop before you can accept this gift."
        } and return
      end
      
      prop = gift.giftable
      prop_instance = current_user.prop_instances.create(
        :prop => prop,
        :gifter => gift.sender
      )
      if prop_instance.persisted?
        gift.destroy
        Worlize.event_logger.info("action=gift_accepted giftable_type=#{gift.giftable_type} giftable_guid=#{gift.giftable.guid} gift_id=#{gift.id} sender=#{gift.sender ? gift.sender.guid : 'none'} recipient=#{gift.recipient.guid}")
        render :json => {
          :success => true,
          :data => prop_instance.hash_for_api
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
