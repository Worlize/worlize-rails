class Locker::BackgroundsController < ApplicationController
  before_filter :require_user
  def index
    result = current_user.background_instances.map do |i|
      i.hash_for_api
    end
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :capacity => current_user.background_slots,
      :count => result.length,
      :data => result
    })
  end

  def create
    name = params[:name] || "Background by #{current_user.username}"
    
    @background = Background.new(:name => name,
                         :sale_coins => 0,
                         :sale_bucks => 0,
                         :return_coins => 0,
                         :creator => current_user,
                         :image => params[:filedata])
    
    if @background.save
      bi = current_user.background_instances.create(:background => @background)
      if (bi.persisted?)
        render :json => Yajl::Encoder.encode({
          :success => true,
          :data => bi.hash_for_api
        })
      else
        render :json => Yajl::Encoder.encode({
          :success => false,
          :description => "Unable to create background instance."
        })
      end
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "Background is invalid.",
        :errors => @background.errors
      })
    end
  end

  def destroy
    instance = current_user.background_instances.find_by_guid(params[:id])
    num_instances_remaining = instance.background.background_instances.count
    if num_instances_remaining == 1
      instance.background.destroy
    else
      instance.destroy
    end
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
