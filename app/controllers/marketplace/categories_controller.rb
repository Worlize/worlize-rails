class Marketplace::CategoriesController < ApplicationController
  layout 'marketplace'

  def index
    params[:id] = MarketplaceCategory.root.id
    show
    render :action => 'show'        
  end
  
  def show
    @category = MarketplaceCategory.find(params[:id])
    
  end

end
