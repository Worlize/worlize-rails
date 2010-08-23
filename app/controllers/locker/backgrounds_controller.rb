class Locker::BackgroundsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.background_instances.map do |i|
      background = i.background
      {
        :guid => i.guid,
        :room => i.room ? {
          :name => i.room.name,
          :guid => i.room.guid
        } : nil,
        :background => background.hash_for_api
      }
    end
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :count => result.length,
      :data => result
    })
  end

  def destroy
    instance = current_user.background_instances.find_by_guid(params[:id])
    instance.destroy

    current_user.credit_account :coins => instance.background.return_coins

    render :json => Yajl::Encoder.encode({
      :success => instance.destroyed?,
      :balance => {
        :coins => current_user.coins,
        :bucks => current_user.bucks
      }
    })
  end
end
