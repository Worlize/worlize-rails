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
    
    success = false
    
    num_instances_remaining = instance.app.app_instances.count
    if num_instances_remaining == 1 && instance.app.marketplace_item.nil?
      instance.app.destroy
      success = instance.app.destroyed?
    else
      instance.destroy
      success = instance.destroyed?
    end

    render :json => {
      :success => success,
      :balance => {
        :coins => current_user.coins,
        :bucks => current_user.bucks
      }
    }
  end
  
  def destroy_all_copies
    app = App.find_by_guid(params[:id])
    if app
      instances = current_user.app_instances.where(:app_id => app.id)
      instance_guids = instances.map { |ai| ai.guid }
      
      num_instances_remaining = app.app_instances.count
      if num_instances_remaining == instances.count && app.marketplace_item.nil?
        app.destroy
      else
        instances.destroy_all
      end
      
      render :json => {
        :success => true,
        :instances => instance_guids
      } and return
    end
    
    render :json => {
      :success => false,
      :message => "Unable to find the specified app."
    }
  end
  
  def get_another_copy
    app = App.find_by_guid(params[:id])
    if app.nil?
      render :json => {
        :success => false,
        :message => 'Cannot find the specified app.'
      } and return
    end
    
    ai = current_user.app_instances.create(:app => app)
    
    result = {
      :success => ai.persisted?
    }
    if result[:success]
      result[:app_instance] = ai.hash_for_api
    end
    
    render :json => result
  end
  
  def remove_from_room
    instance = current_user.app_instances.find_by_guid(params[:id])

    success = !instance.room.nil? && instance.room.room_definition.remove_item(instance.guid)
    
    render :json => {
      :success => true,
      :guid => instance.guid,
      :room => instance.room ? instance.room.basic_hash_for_api : nil
    }
  end
  
end
