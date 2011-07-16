class Marketplace::CategoriesController < ApplicationController
  layout 'marketplace'
  
  before_filter :store_location_if_not_logged_in

  def index
    show
    render :action => 'show'        
  end
  
  def show
    @category = params[:id] ? MarketplaceCategory.find(params[:id]) : MarketplaceCategory.root
    @category_ids = [@category.id].concat @category.subcategory_list.split(',')
    @carousel_items = @category.marketplace_carousel_items.active.map { |i| i.marketplace_featured_item }
  end


end
