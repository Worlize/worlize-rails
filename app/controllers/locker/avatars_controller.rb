class Locker::AvatarsController < ApplicationController

  def index
    avatar_instances = current_user.avatar_instances.all(:include => [:avatar, :user])
      
    render :json => Yajl::Encoder.encode({
      :success => true,
      :count => avatar_instances.length,
      :data => avatar_instances.map { |ai| ai.hash_for_api }
    })
  end
  
  def create
    @avatar = Avatar.new(:name => "Created by #{current_user.username}",
                         :width => 0,
                         :height => 0,
                         :offset_x => 0,
                         :offset_y => 0,
                         :active => true,
                         :sale_coins => 0,
                         :sale_bucks => 0,
                         :return_coins => 0,
                         :creator => current_user,
                         :image => params[:filedata])
    
    if @avatar.save
      ai = current_user.avatar_instances.create(:avatar => @avatar)
      if (ai.persisted?)
        render :json => Yajl::Encoder.encode({
          :success => true,
          :data => ai.hash_for_api
        })
      else
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "Unable to create avatar instance."
        })
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Avatar is invalid.",
        :errors => @avatar.errors
      })
    end
  end
  
  def destroy
    avatar_instance = current_user.avatar_instances.find_by_guid(params[:id])
    num_instances_remaining = avatar_instance.avatar.avatar_instances.count
    if num_instances_remaining == 1
      # destroy the avatar itself if this is its last instance
      avatar_instance.avatar.destroy
    else
      # otherwise just destroy the instance
      avatar_instance.destroy
    end
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end
  
end
