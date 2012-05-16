class Locker::AppsController < ApplicationController
  before_filter :require_user
  
  def index
    result = current_user.app_instances.includes(:app, :room => :world).order('created_at DESC').map do |o|
      o.hash_for_api
    end
    
    render :json => {
      :success => true,
      :capacity => current_user.app_slots,
      :count => result.length,
      :data => result
    }
  end
  
  def create
    if !current_user.developer?
      render :json => {
        :success => false,
        :description => "Only developers can upload SWF apps."
      } and return
    end
    
    name = params[:name] || "Untitled App"
    
    @app = App.new(
      :name => name,
      :creator => current_user,
      :width => params[:width],
      :height => params[:height],
      :app => params[:filedata]
    )
    
    if @app.save
      ai = current_user.app_instances.create(:app => @app)
      if (ai.persisted?)
        render :json => {
          :success => true,
          :data => ai.hash_for_api
        }
      else
        render :json => {
          :success => false,
          :description => "Unable to create app instance."
        }
      end
    else
      Rails.logger.debug("Model errors:\n" + @app.errors.to_s)
      render :json => {
        :success => false,
        :description => "App is invalid.",
        :errors => @app.errors
      }
    end
  end
  
  def destroy
    instance = current_user.app_instances.find_by_guid(params[:id])
    
    if instance.room
      # must yank it from the room where its currently used
      # TODO: Implement this!
    end
    
    num_instances_remaining = instance.app.app_instances.count
    if num_instances_remaining == 1 && instance.app.marketplace_item.nil?
      instance.app.destroy
    else
      instance.destroy
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
