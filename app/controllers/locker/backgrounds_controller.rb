class Locker::BackgroundsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.background_instances.includes(:background, :user).order('created_at DESC').map do |i|
      i.hash_for_api
    end
    
    render :json => {
      :success => true,
      :capacity => current_user.background_slots,
      :count => result.length,
      :data => result
    }
  end

  def buy_slots
    slot_kind = 'background'
    quantity = params[:quantity].to_i
    
    begin
      current_user.buy_slots(slot_kind, quantity)
    rescue Worlize::InsufficientFundsException => e
      render :json => {
        :success => false,
        :insufficient_funds => true,
        :message => e.message
      } and return
    rescue => e
      render :json => {
        :success => false,
        :insufficient_funds => false,
        :message => e.message
      } and return
    end
    
    render :json => {
      :success => true,
      :slot_kind => slot_kind,
      :quantity => quantity
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
      room.save
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
