class Admin::Marketplace::ItemsController < ApplicationController
  layout 'admin'
  before_filter :find_marketplace_item, :only => [:show, :edit, :update, :destroy]

  # GET /marketplace_items
  # GET /marketplace_items.xml
  def index
    @items = MarketplaceItem.where(:marketplace_category_id => nil)

    respond_to do |wants|
      wants.html # index.html.erb
      wants.xml  { render :xml => @marketplace_items }
    end
  end

  # GET /marketplace_items/1
  # GET /marketplace_items/1.xml
  def show
    @category_options_for_select = build_category_options
    
    respond_to do |wants|
      wants.html # show.html.erb
      wants.xml  { render :xml => @marketplace_item }
    end
  end

  # GET /marketplace_items/new
  # GET /marketplace_items/new.xml
  def new
    render :nothing => true and return if params[:item_type].empty?
    @category_options_for_select = build_category_options
    if params[:category_id]
      @category = MarketplaceCategory.find(params[:category_id])
    end
    
    @item = MarketplaceItem.new(:item_type => params[:item_type], :marketplace_category => @category)
    @item.item = case params[:item_type]
      when 'Avatar'
        Avatar.new
      when 'Background'
        Background.new
      when 'InWorldObject'
        InWorldObject.new
    end

    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @marketplace_item }
    end
  end

  # POST /marketplace_items
  # POST /marketplace_items.xml
  def create
    # AutoComplete value for marketplace_creator...
    if !params[:marketplace_item][:marketplace_creator].empty?
      creator_criteria = params[:marketplace_item].delete(:marketplace_creator)
      creator = MarketplaceCreator.find_by_display_name(creator_criteria)
      if creator.nil?
        creator = MarketplaceCreator.create(:display_name => creator_criteria)
      end
      params[:marketplace_item][:marketplace_creator_id] = creator.id
    else
      params[:marketplace_item].delete(:marketplace_creator)
    end

    @item = MarketplaceItem.new(params[:marketplace_item])
    @item.item = case params[:item_type]
      when 'Avatar'
        Avatar.create(params[:avatar])
      when 'Background'
        Background.create(params[:background])
      when 'InWorldObject'
        InWorldObject.create(params[:in_world_object])
      else
        raise "Invalid item type #{params[:item_type]}"
    end
    
    if @item.item.respond_to? 'name='
      @item.item.name = @item.name
    end
    
    puts @item.item

    respond_to do |wants|
      if @item.save
        flash[:notice] = 'Marketplace Item was successfully created.'
        wants.html { 
          if @item.marketplace_category
            redirect_to([:admin, @item.marketplace_category])
          else
            redirect_to([:admin, @item])  
          end
        }
        wants.xml  { render :xml => @item, :status => :created, :location => [:admin, @item] }
      else
        @item.item.destroy
        @category_options_for_select = build_category_options
        wants.html { render :action => "new" }
        wants.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /marketplace_items/1
  # PUT /marketplace_items/1.xml
  def update
    # AutoComplete value for marketplace_creator...
    if !params[:marketplace_item][:marketplace_creator].empty?
      creator_criteria = params[:marketplace_item].delete(:marketplace_creator)
      creator = MarketplaceCreator.find_by_display_name(creator_criteria)
      if creator.nil?
        creator = MarketplaceCreator.create(:display_name => creator_criteria)
      end
      params[:marketplace_item][:marketplace_creator_id] = creator.id
    else
      params[:marketplace_item].delete(:marketplace_creator)
      params[:marketplace_item][:marketplace_creator_id] = nil
    end
    
    respond_to do |wants|
      require 'pp'
      pp params[:marketplace_item]
      if @item.update_attributes(params[:marketplace_item])
        flash[:notice] = 'Marketplace Item was successfully updated.'
        wants.html {
          if @item.marketplace_category
            redirect_to([:admin, @item.marketplace_category])
          else
            redirect_to([:admin, @item])
          end
        }
        wants.xml  { head :ok }
      else
        @category_options_for_select = build_category_options
        wants.html { render :action => "show" }
        wants.xml  { render :xml => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /marketplace_items/1
  # DELETE /marketplace_items/1.xml
  def destroy
    @item.destroy

    respond_to do |wants|
      wants.html {
        if @item.marketplace_category
          redirect_to([:admin, @item.marketplace_category])
        else
          redirect_to(admin_marketplace_items_path)
        end
      }
      wants.xml  { head :ok }
    end
  end

  private
    def find_marketplace_item
      @item = MarketplaceItem.find(params[:id])
    end
    
    def build_category_options(root=nil, level=0)
      root ||= MarketplaceCategory.where(:parent_id => nil).first
      options = [];

      root.children.each do |category|
        options.push([('-'.html_safe * level) + ' ' + category.name, category.id])
        options = options + build_category_options(category, level + 1)
      end
      return options
    end

end
