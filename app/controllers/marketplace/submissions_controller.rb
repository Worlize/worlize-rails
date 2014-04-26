class Marketplace::SubmissionsController < ApplicationController
  layout 'bootstrap'
  before_filter :require_user
  before_filter :store_location_if_not_logged_in

  def index
    
  end

  def new
    render :nothing => true and return if params[:item_type].empty?
    
    unless ['Avatar','Background','InWorldObject','Prop'].include?(params[:item_type])
      flash[:error] = "Invalid item type."
      redirect_to marketplace_submissions_path and return
    end
    
    @item = MarketplaceItem.new(
      :item_type => params[:item_type],
      :marketplace_category => @category,
      :on_sale => true,
      :currency_id => 1
    )
    @item.item = case params[:item_type]
      when 'Avatar'
        Avatar.new
      when 'Background'
        Background.new
      when 'InWorldObject'
        InWorldObject.new
      when 'Prop'
        Prop.new
    end

    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @item }
    end
  end
  
  def create
    @creator = current_user.marketplace_creator
    if @creator.nil?
      flash[:error] = "There is no marketplace artist record for your account."
      redirect_to marketplace_submissions_path and return
    end

    @item = MarketplaceItem.new(params[:marketplace_item])
    @item.creator = @creator
    @item.user_submission = true
    @item.item = case params[:item_type]
      when 'Avatar'
        Avatar.create(params[:avatar])
      when 'Background'
        Background.create(params[:background])
      when 'InWorldObject'
        InWorldObject.create(params[:in_world_object])
      when 'Prop'
        Prop.create(params[:prop])
      else
        flash[:error] = "Invalid item type."
        redirect_to marketplace_submissions_path and return
    end
    
    if @item.item.respond_to? 'name='
      @item.item.name = @item.name
    end

    respond_to do |wants|
      if @item.save
        flash[:notice] = 'Your item has been submitted successfully.'
        
        wants.html { 
          redirect_to marketplace_submissions_path
        }
      else
        @item.item.destroy
        
        wants.html { render :action => 'new' }
      end
    end
  end
end
