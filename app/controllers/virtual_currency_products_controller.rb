class VirtualCurrencyProductsController < ApplicationController

  layout "plain"

  def index
    @products = VirtualCurrencyProduct.where(:archived => false)
  end
  
  def return
    
  end
  
end
