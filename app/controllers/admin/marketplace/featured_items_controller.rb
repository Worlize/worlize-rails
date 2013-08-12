class Admin::Marketplace::FeaturedItemsController < ApplicationController
  layout "admin"
  before_filter { |c| c.require_all_permissions(:can_administrate_marketplace) }
  before_filter :load_featured_item, :only => [:show, :update, :destroy]
  
  def index
    @item = MarketplaceItem.find(params[:item_id])
    @featured_items = @item.marketplace_featured_items
  end
  
  def show
    @item = @featured_item.featured_item
    @category_options_for_select = build_category_options    
  end
  
  def new
    if params[:featured_item_type] == 'MarketplaceItem'
      @item = MarketplaceItem.find(params[:featured_item_id]) if params[:featured_item_id]
    elsif params[:featured_item_type] == 'MarketplaceCategory'
      @item = MarketplaceCategory.find(params[:featured_item_id]) if params[:featured_item_id]
    end
    @category_options_for_select = build_category_options
    @featured_item = MarketplaceFeaturedItem.new(:featured_item => @item, :active => true)
    
    if !@item.nil? && @item.respond_to?('marketplace_category')
      @featured_item.marketplace_category = @item.marketplace_category
    else
      @featured_item.marketplace_category = nil
    end
  end
  
  def create
    @category_options_for_select = build_category_options
    @featured_item = MarketplaceFeaturedItem.new(params[:marketplace_featured_item])
    @featured_item.creator = current_user
    respond_to do |wants|
      if @featured_item.save
        flash[:notice] = "Featured item successfully created"
        wants.html { redirect_back_or_default [:admin, @featured_item.featured_item] }
      else
        @item = @featured_item.featured_item
        wants.html { render :action => :new }
      end
    end
  end
  
  def update
    respond_to do |wants|
      if @featured_item.update_attributes(params[:marketplace_featured_item])
        flash[:notice] = "Featured item successfully updated"
        wants.html { redirect_back_or_default [:admin, @featured_item.featured_item] }
      else
        @category_options_for_select = build_category_options
        @item = @featured_item.featured_item
        wants.html { render :action => :show }
      end
    end
  end
  
  def destroy
    respond_to do |wants|
      if @featured_item.destroy
        wants.html { redirect_to [:admin, @featured_item.featured_item], :anchor => 'featured_items' }
      else
        flash[:error] = "Unable to delete the featured item."
        wants.html { redirect_to [:admin, @featured_item.featured_item] }
      end
    end
  end
  
  private
  
  def load_featured_item
    @featured_item = MarketplaceFeaturedItem.find(params[:id])
  end

  def build_category_options(root=nil, level=0)
    options = [];

    if root.nil?
      root = MarketplaceCategory.where(:parent_id => nil).first
      options.push([root.name, root.id])
    end

    root.children.each do |category|
      options.push([ category.name_with_breadcrumbs, category.id ])
      options = options + build_category_options(category, level + 1)
    end
    return options
  end

    
end
