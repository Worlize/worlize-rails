class Marketplace::ThemesController < ApplicationController
  def show
    @theme = MarketplaceTheme.find(params[:id])
    render :text => @theme.css, :content_type => 'text/css'
  end
end
