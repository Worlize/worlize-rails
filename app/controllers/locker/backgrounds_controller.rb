class Locker::BackgroundsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.background_instances.map do |i|
      i.hash_for_api
    end
    
    render :json => {
      :success => true,
      :capacity => current_user.background_slots,
      :count => result.length,
      :data => result
    }
  end

  def create
    name = params[:name] || "Background by #{current_user.username}"
    
    @background = Background.new(:name => name,
                         :creator => current_user,
                         :image => params[:filedata])
    
    if @background.save
      bi = current_user.background_instances.create(:background => @background)
      if (bi.persisted?)
        render :json => {
          :success => true,
          :data => bi.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "Unable to create background instance."
        }
      end
    else
      render :json => {
        :success => false,
        :description => "Background is invalid.",
        :errors => @background.errors
      }
    end
  end

  def destroy
    instance = current_user.background_instances.find_by_guid(params[:id])
    num_instances_remaining = instance.background.background_instances.count

    if instance.room
      room = instance.room
      room.background_instance = nil
      if room.save
        Worlize::InteractServerManager.instance.broadcast_to_room(room.guid, {
          :msg => 'room_definition_updated'
        })
      end
    end
    
    if instance.background.do_not_delete
      instance.destroy
    else
      if num_instances_remaining == 1 && instance.background.marketplace_item.nil?
        instance.background.destroy
      else
        instance.destroy
      end
    end
    
    render :json => {
      :success => instance.destroyed?,
      :balance => {
        :coins => current_user.coins,
        :bucks => current_user.bucks
      }
    }
  end
end
