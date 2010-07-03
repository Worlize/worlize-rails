class WorldsController < ApplicationController
  def show
  end

  def edit
    @world = World.find(params[:id])
  end

  def destroy
    @world = World.find(params[:id])
    name = @world.name
    if (@world.destroy)
      # flash['notice'] = "#{name} successfully deleted"
    else
      # flash['error'] = "There was an error while deleting #{name}"
    end
    redirect_to worlds_url
  end

  def create
    @world = World.new(params[:world])
    if @world.save
      # flash['notice'] = "#{@world.name} created successfully"
      redirect_to worlds_url
    else
      render :action => :new
    end
  end

  def new
    @world = World.new
  end

  def index
    @worlds = World.all
  end

  def update
    @world = World.find(params[:id])
    if @world.update_attributes(params[:world])
      flash[:notice] = "#{@world.name} updated successfully"
      redirect_to worlds_url
    else
      flash[:notice] = "Unable to update worlz"
      render :action => :edit
    end
  end

end
