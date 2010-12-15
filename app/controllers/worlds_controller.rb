class WorldsController < ApplicationController
  before_filter :require_user
  
  def show
    world = World.find_by_guid(params[:id])
    if world
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => world.hash_for_api(current_user)
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "There is no such world."
      })
    end
  end
  
  def user_list
    world = World.find_by_guid(params[:id])
    if world
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => world.user_list
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "There is no such world."
      })
    end
  end
  
end
