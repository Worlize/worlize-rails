class VirtualCurrencyProductsController < ApplicationController

  layout "plain"

  def index
    @products = VirtualCurrencyProduct.where(:archived => false).order(:position)
  end
  
  def return
    
  end
  
end
