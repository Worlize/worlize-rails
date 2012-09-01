class ModeratorsController < ApplicationController
  before_filter :require_user
  
  def index
    world = World.find_by_guid!(params[:world_id])
    
    permissions = current_user.applied_permissions(world.guid)
    has_permission = permissions.include?('can_access_moderation_dialog')
    
    if !has_permission
      render :json => {
        :success => false,
        :message => "Permission denied"
      } and return
    end
    
    moderators = world.moderators.map do |user|
      world_permissions = user.permissions(world.guid, false)
      global_permissions = user.permissions
      applied_permissions = world_permissions | global_permissions
      
      user.public_hash_for_api.merge({
        :permissions => {
          :world => world_permissions,
          :global => global_permissions,
          :applied => applied_permissions
        }
      })
    end
    
    owner = moderators.select {|u| u[:guid] == world.user.guid }.first
    moderators = moderators.reject {|u| u[:guid] == world.user.guid }
    
    result = {
      :success => true,
      :owner => owner,
      :moderators => moderators
    }
    
    render :json => result
  end
  
  def update_moderation_data
    world = World.find_by_guid!(params[:world_id])
    user_permissions = current_user.applied_permissions(world.guid)
    
    begin
      data = Yajl::Parser.parse(params[:data])
    rescue
      render :json => {
        :success => false,
        :error => {
          :message => "Unable to parse JSON data",
          :code => 0 # TODO: design a system for error codes
        }
      } and return
    end
    
    if !data['moderators'].nil? && user_permissions.include?('can_grant_permissions')
      data['moderators'].each do |moderator_data|
        user = User.find_by_guid(moderator_data['guid'])
        unless user.nil?
          user.set_permissions(moderator_data['permissions']['world'], world.guid)
        end
      end
    end
    
    render :json => {
      :success => true
    }
  end
  
  def update
    world = World.find_by_guid!(params[:world_id])
    @user = User.find_by_guid!(params[:id])
    
    unless current_user.applied_permissions(world.guid).include?('can_grant_permissions')
      render :json => {
        :success => false,
        :error => {
          :message => "Permission Denied",
          :code => 0 # TODO: design a system for error codes
        }
      }
      return
    end
    
    begin
      data = Yajl::Parser.parse(params[:data])
      if Rails.env == 'development'
        require 'pp'
        pp data
      end
    rescue
      render :json => {
        :success => false,
        :error => {
          :message => "Unable to parse JSON data",
          :code => 0 # TODO: design a system for error codes
        }
      } and return
    end
    
    permissions = data['permissions'] ? data['permissions'] : []
    @user.set_permissions(permissions, world.guid)
    
    render :json => {
      :success => true
    }
  end
  
  def destroy
    world = World.find_by_guid!(params[:world_id])
    @user = User.find_by_guid!(params[:id])
    unless current_user.applied_permissions(world.guid).include?('can_grant_permissions')
      render :json => {
        :success => false,
        :error => {
          :message => "Permission Denied",
          :code => 0 # TODO: design a system for error codes
        }
      }
      return
    end
    
    @user.set_permissions([], world.guid)
    
    render :json => {
      :success => true,
      :removed_moderator_guid => @user.guid
    }
  end
end
