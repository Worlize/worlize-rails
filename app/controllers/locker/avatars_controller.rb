class Locker::AvatarsController < ApplicationController

  def index
    avatar_instances = current_user.avatar_instances.includes(:avatar, :user).order('created_at DESC').all
      
    render :json => {
      :success => true,
      :count => avatar_instances.length,
      :capacity => current_user.avatar_slots,
      :data => avatar_instances.map { |ai| ai.hash_for_api }
    }
  end
  
  def buy_slots
    slot_kind = 'avatar'
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
    if current_user.avatar_slots <= current_user.avatar_instances.count
      render :json => {
        :success => false,
        :description => "You cannot upload any more avatars."
      } and return
    end
    
    @avatar = Avatar.new(:name => "Created by #{current_user.username}",
                         :width => 0,
                         :height => 0,
                         :offset_x => 0,
                         :offset_y => 0,
                         :active => true,
                         :creator => current_user,
                         :image => params[:filedata])
    
    if @avatar.save
      ai = current_user.avatar_instances.create(:avatar => @avatar)
      if (ai.persisted?)
        render :json => {
          :success => true,
          :data => ai.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "Unable to create avatar instance."
        }
      end
    else
      render :json => {
        :success => false,
        :description => "Avatar is invalid.",
        :errors => @avatar.errors
      }
    end
  end
  
  def destroy
    avatar_instance = current_user.avatar_instances.find_by_guid(params[:id])
    if avatar_instance.nil?
      render :json => {
        :sucess => false
      } and return
    end
    
    num_instances_remaining = avatar_instance.avatar.avatar_instances.count
    gifts_remaining = avatar_instance.avatar.gifts.count
    if num_instances_remaining == 1 && gifts_remaining == 0 &&
        avatar_instance.avatar.marketplace_item.nil?
      # destroy the avatar itself if this is its last instance
      # but don't destroy the avatar if it exists in the marketplace
      avatar_instance.avatar.destroy
    else
      # otherwise just destroy the instance
      avatar_instance.destroy
    end
    render :json => {
      :success => true
    }
  end
  
end
