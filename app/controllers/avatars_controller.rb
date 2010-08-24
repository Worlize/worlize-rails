class AvatarsController < ApplicationController
  def show
    avatar = Avatar.find_by_guid(params[:id])
    if avatar
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => avatar.hash_for_api
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Unable to find the specified avatar"
      })
    end
  end
end
