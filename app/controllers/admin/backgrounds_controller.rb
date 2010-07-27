class Admin::BackgroundsController < ApplicationController
  def show
    @background = Background.find(params[:id])
  end

  def new
    @background = Background.new
  end
  
  def create
    @background = Background.new(params[:background])
    if @background.save
      flash[:notice] = "Background image saved successfully"
      redirect_to admin_backgrounds_url
    else
      flash.now[:notice] = "Unable to save background image"
      render :new
    end
  end

  def index
    @backgrounds = Background.all
  end

end
