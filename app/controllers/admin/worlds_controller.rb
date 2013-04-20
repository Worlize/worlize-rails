class Admin::WorldsController < ApplicationController
  layout 'admin'
  
  before_filter :require_global_moderator_permission
  
  def show
    @world = World.find(params[:id])
  end
end
