class Admin::RoomsController < ApplicationController
  
  before_filter :require_user
  
  def index
    @world = World.find(params[:world_id])
    @rooms = @world.rooms
    respond_to do |format|
      format.html
      format.json { render :json => @rooms }
    end
  end

  def edit
    @world = World.find(params[:world_id])
    @room = @world.rooms.find(params[:id])
  end

  def new
    @world = World.find(params[:world_id])
    @room = @world.rooms.new(:world => @world)
  end

  def update
    @world = World.find(params[:world_id])
    @room = @world.rooms.find(params[:id])
    if @room.update_attributes(params[:room])
      flash[:notice] = "Room #{@room.name} successfully updated."
      redirect_to admin_world_rooms_url(@world)
    else
      flash[:notice] = "Unable to update room #{@room.name}"
      render :edit
    end
  end

  def create
    @world = World.find(params[:world_id])
    @room = @world.rooms.new(params[:room])
    if @room.save
      flash[:notice] = "Room #{@room.name} successfully saved."
      redirect_to admin_world_rooms_url(@world)
    else
      flash[:notice] = "Unable to create room #{@room.name}."
      render :new
    end
  end

  def destroy
    @world = World.find(params[:world_id])
    @room = @world.rooms.find(params[:id])
    if @room.destroy
      flash[:notice] = "Room #{@room.name} successfully deleted"
      redirect_to admin_world_rooms_url(@world)
    else
      flash[:notice] = "Unable to delete room #{@room.name}"
      redirect_to admin_world_rooms_url(@world)
    end
  end

end
