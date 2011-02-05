class Marketplace::CategoriesController < ApplicationController
  layout 'marketplace'
  
  before_filter :store_location_if_not_logged_in

  def index
    params[:id] = MarketplaceCategory.root.id
    show
    render :action => 'show'        
  end
  
  def show
    @category = MarketplaceCategory.find(params[:id])
    @carousel_items = @category.marketplace_carousel_items.active.map { |i| i.marketplace_featured_item }
  end


end
