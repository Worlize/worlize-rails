class Admin::Marketplace::CategoriesController < ApplicationController
  layout "admin"
  before_filter :require_admin
  
  def index
    root_category = MarketplaceCategory.where(:parent_id => nil).first
    if root_category.nil?
      root_category = MarketplaceCategory.create(:name => 'Marketplace');
    end
    
    redirect_to admin_marketplace_category_path(root_category)
  end
  
  def show
    @category = MarketplaceCategory.find(params[:id])
    @breadcrumbs = build_breadcrumbs(@category)
  end
  
  def create
    @category = MarketplaceCategory.new(params[:marketplace_category])
    
    respond_to do |format|
      if @category.save
        format.html { redirect_to admin_marketplace_category_path(@category.parent) }
        format.js
      else
        format.html { render :action => :new }
        format.js { render :action => :new }
      end
    end
  end
  
  def destroy
    @category = MarketplaceCategory.find(params[:id])
    
    if @category.children.count > 0
      flash[:error] = "You cannot delete a category while it still has subcategories."
      redirect_to admin_marketplace_category_path(@category) and return
    end
    
    @category.destroy
    
    redirect_to admin_marketplace_category_path(@category.parent)
  end
  
  def update_subcategory_positions
    order = params[:order]
    if order.instance_of?(Array)
      order.each_index do |i|
        MarketplaceCategory.update_all(
          { :position => i+1 },
          { :id => order[i], :parent_id => params[:id] }
        )
      end
    end
    render :nothing => true
  end
  
  private
  
  def build_breadcrumbs(category)
    breadcrumbs = [category]
    while category.parent
      category = category.parent
      breadcrumbs.unshift(category)
    end
    return breadcrumbs
  end
end
