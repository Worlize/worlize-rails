class AviaryController < ApplicationController
  before_filter :require_user
  
  def edit_complete
    Rails.logger.debug params.to_yaml
    
    case params[:type]
    when 'avatar'
      save_avatar(params)
    else
      render :text => "Invalid item type: #{params[:type]}", :status => 400
    end
  end
  
  private
  
  def save_avatar(params)
    # Try to find the instance that we'll be replacing
    existing_instance = current_user.avatar_instances.where(:edit_guid => params[:edit_guid]).first
    if existing_instance.nil?
      message = "Unable to find avatar instance with edit guid #{params[:edit_guid]}"
      Rails.logger.error(message)
      render :text => message, :status => 404 and return false
    end
    
    # Did the user save as a copy?
    # saved_as_copy = (!existing_instance.aviary_guid.nil? &&
    #                  existing_instance.aviary_guid != params[:fileguid])

    # We don't support saving as a copy for now.
    saved_as_copy = false
    
    locker_full = (current_user.avatar_slots <= current_user.avatar_instances.count)

    # Create a new avatar sourced from the URL provided by Aviary.
    new_avatar = Avatar.new(:name => params[:name],
                            :width => 0,
                            :height => 0,
                            :offset_x => 0,
                            :offset_y => 0,
                            :active => true,
                            :creator => current_user,
                            :remote_image_url => params[:imageurl])
    if !new_avatar.save
      message = "Avatar is invalid.\n#{new_avatar.errors.to_yaml}"
      Rails.logger.error(message)
      render :text => message, :status => 500 and return false
    end
    
    # Create a new instance for this avatar, but re-use the old edit_guid
    # so that we can handle the case when the user hits "save" multiple
    # times in the Aviary editor.
    new_instance = current_user.avatar_instances.create(
      :avatar => new_avatar,
      :edit_guid => saved_as_copy ? nil : existing_instance.edit_guid,
      :aviary_guid => params[:fileguid]
    )
    if !new_instance.persisted?
      # Instance couldn't be saved.. reap the orphaned avatar.
      new_avatar.destroy
      Rails.logger.error("Unable to create avatar instance saving from Aviary.  User guid #{current_user.guid}")
      render :text => "Unable to save new avatar instance."
    end
    
    if !saved_as_copy
      # Lets get rid of the old avatar now.
      num_instances_remaining = existing_instance.avatar.avatar_instances.count
      gifts_remaining = existing_instance.avatar.gifts.count
      if num_instances_remaining == 1 && gifts_remaining == 0 &&
          existing_instance.avatar.marketplace_item.nil?
        # destroy the avatar itself if this is its last instance
        # but don't destroy the avatar if it exists in the marketplace
        existing_instance.avatar.destroy
      else
        # otherwise just destroy the instance
        existing_instance.destroy
      end
    end
  
    message = 'Successfully replaced existing avatar with edited version.'
    Rails.logger.debug(message)
    render :text => message, :status => 200
  end
end
