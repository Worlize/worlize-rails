class DashboardController < ApplicationController
  before_filter :require_user
  
  def show
    @user = current_user
    @user.finish_linking_external_accounts if @user.linking_external_accounts?
    @world = @user.worlds.first
    if @world
      @room = @world.rooms.first
    end
  end
end
