class Locker::AvatarsController < ApplicationController
  before_filter :require_user
  
  def index
    avatar_instances = current_user.avatar_instances.includes(:avatar, :user).order('created_at DESC').all
      
    render :json => {
      :success => true,
      :count => avatar_instances.length,
      :capacity => current_user.avatar_slots,
      :data => avatar_instances.map { |ai| ai.hash_for_api }
    }
  end
  
  def save_instance
    @avatar = Avatar.find_by_guid(params[:id])
    
    if @avatar.nil?
      render :json => {
        :success => false,
        :description => "Unable to find an avatar with the specified guid."
      } and return
    end
    
    if current_user.avatar_instances.include? @avatar
      render :json => {
        :success => false,
        :description => "You already have that avatar in your locker."
      } and return
    end
    
    ai = current_user.avatar_instances.create(:avatar => @avatar)
    
    if ai.persisted?
      render :json => {
        :success => true
      }
    else
      render :json => {
        :success => false,
        :description => "Unable to create avatar instance.",
        :errors => ai.errors
      }
    end
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
                         :animated_gif => params[:animated_gif],
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
        :description => "Avatar rejected: #{@avatar.errors.full_messages.join(', ')}",
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
      # TODO: FIXME: We currently don't ever delete any avatars in case they
      # are in an avatar dispenser and you delete the only copy from your
      # locker!
      
      # destroy the avatar itself if this is its last instance
      # but don't destroy the avatar if it exists in the marketplace
      # avatar_instance.avatar.destroy
      avatar_instance.destroy
    else
      # otherwise just destroy the instance
      avatar_instance.destroy
    end
    render :json => {
      :success => true
    }
  end
  
end
