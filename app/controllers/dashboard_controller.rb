class DashboardController < ApplicationController
  before_filter :require_user
  
  def show
    @user = current_user
    @world = @user.worlds.first
    if @world
      @room = @world.rooms.first
    end
    redirect_to enter_room_url(@room.guid)
  end
end
