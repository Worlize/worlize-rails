class Locker::AvatarsController < ApplicationController

  def index
    avatar_instances = current_user.avatar_instances
    avatars = avatar_instances.map { |ai| ai.avatar.hash_for_api }
      
    render :json => Yajl::Encoder.encode({
      :success => true,
      :count => avatars.length,
      :data => avatars
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
          :data => @avatar.hash_for_api
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
  
end
