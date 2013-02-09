class Admin::ModeratorsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  
  def index
    @moderators = User.global_moderators
  end
end
