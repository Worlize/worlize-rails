class Admin::EventRoomOptionsController < ApplicationController
  layout "admin"
  before_filter :require_admin

  def new
    @event_theme = EventTheme.find(params[:event_theme_id])
    @event_category = @event_theme.event_category
    @event_room_option = EventRoomOption.new
    @event_room_option.event_theme = @event_theme
  end

  def index
    @event_theme = EventTheme.find(params[:event_theme_id])
    @event_room_options = @event_theme.event_room_options
  end
  
  def create
    @event_theme = EventTheme.find(params[:event_theme_id])
    @event_room_option = @event_theme.event_room_options.build(params[:event_room_option])
    if @event_room_option.save
      flash[:notice] = "Room option \"#{@event_room_option.name}\" saved successfully."
      redirect_to admin_event_category_event_theme_url(@event_theme.event_category_id, @event_theme)
    else
      render :action => :new
    end
  end
  
  def destroy
    @event_room_option = EventRoomOption.find(params[:id])
    if @event_room_option.destroy
      flash[:notice] = "Room option \"#{@event_room_option.name}\" deleted successfully."
    else
      flash[:error] = "Unable to delete event room option."
    end
    theme = @event_room_option.event_theme
    category = theme.event_category
    redirect_to admin_event_category_event_theme_url(category, theme)
  end
end
