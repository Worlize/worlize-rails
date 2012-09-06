class Admin::EventThemesController < ApplicationController
  
  layout "admin"
  before_filter :require_admin
  
  def new
    @event_category = EventCategory.find(params[:event_category_id])
    @event_theme = EventTheme.new
    @event_theme.event_category = @event_category
  end
  
  def show
    @event_theme = EventTheme.find(params[:id])
    @event_category = @event_theme.event_category
  end
  
  def create
    @event_category = EventCategory.find(params[:event_category_id])
    @event_theme = @event_category.event_themes.build(params[:event_theme])
    if @event_theme.save
      flash[:notice] = "Theme \"#{@event_theme.name}\" saved successfully."
      redirect_to admin_event_category_url(@event_theme.event_category)
    else
      render :action => :new
    end
  end
  
  def update
    @event_category = EventCategory.find(params[:event_category_id])
    @event_theme = EventTheme.find(params[:id])
    
    if @event_theme.update_attributes(params[:event_theme])
      flash[:notice] = "Theme \"#{@event_theme.name}\" saved successfully."
      redirect_to admin_event_category_event_theme_url(@event_category, @event_theme)
    else
      render :action => :show
    end
  end
  
  def destroy
    @event_theme = EventTheme.find(params[:id])
    if @event_theme.destroy
      flash[:notice] = "Theme \"#{@event_theme.name}\" deleted successfully."
      redirect_to admin_event_category_url(@event_theme.event_category_id)
    else
      flash[:error] = "Unable to delete theme."
      redirect_to admin_event_category_event_theme_url(@event_theme.event_category_id, @event_theme)
    end
  end
end
