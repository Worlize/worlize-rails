class Admin::EventCategoriesController < ApplicationController
  layout "admin"
  before_filter :require_admin

  def index
    @categories = EventCategory.all
    @event_category = EventCategory.new
  end
  
  def show
    @event_category = EventCategory.find(params[:id])
    @event_theme = EventTheme.new
    # @event_theme.event_category = @event_category
  end
  
  def create
    @event_category = EventCategory.create(params[:event_category])
    redirect_to admin_event_categories_url
  end
  
  def update
    @event_category = EventCategory.find(params[:id])
    if @event_category.update_attributes(params[:event_category])
      flash[:notice] = "Successfully saved event category."
      redirect_to admin_event_category_url(@event_category)
    else
      @event_theme = EventTheme.new
      render :action => 'show'
    end
  end
  
  def destroy
    
  end
end
