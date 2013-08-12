class Admin::Marketplace::CategoriesController < ApplicationController
  layout "admin"
  before_filter { |c| c.require_all_permissions(:can_administrate_marketplace) }
  
  def index
    params[:id] = MarketplaceCategory.root.id
    show
    render :action => 'show'
  end
  
  def show
    @category = MarketplaceCategory.find(params[:id])
    @breadcrumbs = @category.breadcrumbs
    store_location
  end
  
  def create
    @category = MarketplaceCategory.new(params[:marketplace_category])
    
    respond_to do |format|
      if @category.save
        format.html { redirect_to [:admin, @category.parent] }
      else
        format.html { redirect_to [:admin, @category.parent] }
      end
    end
  end
  
  def update
    @category = MarketplaceCategory.find(params[:id])
    @breadcrumbs = @category.breadcrumbs

    respond_to do |format|
      if @category.update_attributes(params[:marketplace_category])
        format.html { redirect_to([:admin, @category], :notice => 'Category was successfully updated.') }
        # format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        # format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @category = MarketplaceCategory.find(params[:id])
    
    if @category.children.count > 0
      flash[:error] = "You cannot delete a category while it still has subcategories."
      redirect_to admin_marketplace_category_path(@category) and return
    end
    
    if @category.marketplace_items.count > 0
      flash[:error] = "You cannot delete a category while it still has items in it."
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
    render :json => {
      :success => true
    }
  end

  def update_featured_item_positions
    order = params[:order]
    if order.instance_of?(Array)
      order.each_index do |i|
        search_criteria = {
          :id => order[i],
          :marketplace_category_id => params[:id]
        }
        if params[:type] == 'Category'
          search_criteria[:featured_item_type] = 'MarketplaceCategory'
        else
          search_criteria[:featured_item_type] = 'MarketplaceItem'
          search_criteria[:item_type] = params[:type]
        end
        MarketplaceFeaturedItem.update_all( { :position => i+1 }, search_criteria )
      end
    end
    render :json => {
      :success => true
    }
  end
  
  def update_carousel_item_positions
    order = params[:order]
    if order.instance_of?(Array)
      order.each_index do |i|
        MarketplaceCarouselItem.update_all(
          { :position => i+1 },
          {
            :id => order[i],
            :marketplace_category_id => params[:id]
          }
        )
      end
    end
    render :json => {
      :success => true
    }
  end
  
end
