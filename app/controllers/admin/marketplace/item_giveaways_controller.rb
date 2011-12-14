class Admin::Marketplace::ItemGiveawaysController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  
  def new
    @item = MarketplaceItem.find(params[:marketplace_item])
    @item_giveaway = MarketplaceItemGiveaway.new({
      :marketplace_item => @item,
      :name => @item.name,
      :description => @item.description
    })
    @promo_program_options_for_select = build_promo_program_options
  end
  
  def show
    @item_giveaway = MarketplaceItemGiveaway.find(params[:id])
    @item = @item_giveaway.marketplace_item
    @promo_program_options_for_select = build_promo_program_options
  end
  
  def create
    @item_giveaway = MarketplaceItemGiveaway.new(params[:marketplace_item_giveaway])
    @item = @item_giveaway.marketplace_item
    @promo_program_options_for_select = build_promo_program_options
    
    respond_to do |format|
      if @item_giveaway.save
        format.html { redirect_to(admin_marketplace_item_url(@item_giveaway.marketplace_item), :notice => 'Item giveaway was successfully scheduled.') }
        format.xml  { render :xml => @item_giveaway, :status => :created, :location => [:admin, @item_giveaway] }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @item_giveaway.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def update
    @item_giveaway = MarketplaceItemGiveaway.find(params[:id])
    @item = @item_giveaway.marketplace_item
    @promo_program_options_for_select = build_promo_program_options
    
    respond_to do |format|
      if @item_giveaway.update_attributes(params[:marketplace_item_giveaway])
        format.html { redirect_to(admin_marketplace_item_giveaway_url(@item_giveaway), :notice => 'Item Giveaway was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @item_giveaway.errors, :status => :unprocessable_entity }
      end
    end
    
  end
  
  def destroy
    @item_giveaway = MarketplaceItemGiveaway.find(params[:id])
    @item = @item_giveaway.marketplace_item
    @item_giveaway.destroy

    respond_to do |format|
      format.html { redirect_to(admin_marketplace_item_url(@item)) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def build_promo_program_options
    PromoProgram.all.map do |program|
      [program.name, program.id]
    end
  end
    
end
