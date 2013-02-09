class Admin::WorldsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  
  def show
    @world = World.find(params[:id])
  end
end
