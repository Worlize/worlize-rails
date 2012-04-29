class Locker::PropsController < ApplicationController
  before_filter :require_user

  def index
    prop_instances = current_user.prop_instances.includes(:prop, :user).order('created_at DESC').all
      
    render :json => {
      :success => true,
      :count => prop_instances.length,
      :capacity => current_user.prop_slots,
      :data => prop_instances.map { |pi| pi.hash_for_api }
    }
  end
  
  def create
    if current_user.prop_slots <= current_user.prop_instances.count
      render :json => {
        :success => false,
        :description => "You cannot upload any more props."
      } and return
    end
    
    @prop = Prop.new(:name => "Created by #{current_user.username}",
                     :width => 0,
                     :height => 0,
                     :offset_x => 0,
                     :offset_y => 0,
                     :active => true,
                     :creator => current_user,
                     :image => params[:filedata])
    
    if @prop.save
      pi = current_user.prop_instances.create(:prop => @prop)
      if (pi.persisted?)
        render :json => {
          :success => true,
          :data => pi.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "Unable to create prop instance."
        }
      end
    else
      render :json => {
        :success => false,
        :description => "Prop is invalid.",
        :errors => @prop.errors
      }
    end
  end
  
  def destroy
    prop_instance = current_user.prop_instances.find_by_guid(params[:id])
    if prop_instance.nil?
      render :json => {
        :sucess => false
      } and return
    end
    
    num_instances_remaining = prop_instance.prop.prop_instances.count
    gifts_remaining = prop_instance.prop.gifts.count
    if num_instances_remaining == 1 && gifts_remaining == 0 &&
        prop_instance.prop.marketplace_item.nil?
      # destroy the prop itself if this is its last instance
      # but don't destroy the prop if it exists in the marketplace

      # FIXME: We can't delete props at all right now because
      # they could still be sitting in a room even after being
      # deleted from the person's locker, and subsequent people
      # who entered the room would get a broken image.

      # prop_instance.prop.destroy
      prop_instance.destroy
    else
      # otherwise just destroy the instance
      prop_instance.destroy
    end
    render :json => {
      :success => true
    }
  end

end
