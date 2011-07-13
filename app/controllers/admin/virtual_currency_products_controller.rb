class Admin::VirtualCurrencyProductsController < ApplicationController
  layout "admin"
  before_filter :require_admin
  
  def index
    @products = VirtualCurrencyProduct.where(:archived => false).order(:position)
    respond_to do |format|
      format.html # index.html.erb
    end
  end
  
  def new
    @product = VirtualCurrencyProduct.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def move_higher
    @product = VirtualCurrencyProduct.find(params[:id])
    @product.move_higher
    @product.save
    
    respond_to do |format|
      format.html { redirect_to(admin_virtual_currency_products_url) }
    end
  end
  
  def move_lower
    @product = VirtualCurrencyProduct.find(params[:id])
    @product.move_lower
    @product.save
    
    respond_to do |format|
      format.html { redirect_to(admin_virtual_currency_products_url) }
    end
  end
  
  def create
    @product = VirtualCurrencyProduct.new(params[:virtual_currency_product])

    respond_to do |format|
      if @product.save
        format.html { redirect_to(admin_virtual_currency_products_url, :notice => 'Virtual Currency Product was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def archive
    @product = VirtualCurrencyProduct.find(params[:id])
    
    respond_to do |format|
      if @product.update_attribute(:archived, true)
        format.html { redirect_to(admin_virtual_currency_products_url, :notice => 'Virtual Currency Product was archived.') }
      else
        format.html { redirect_to(admin_virtual_currency_products_url, :notice => 'Unable to archive Virtual Currency Product.') }
      end
    end
  end
  
end
