class Admin::ModeratorsController < ApplicationController
  layout 'admin'
  
  before_filter :require_global_moderator_permission
  
  def index
    @moderators = User.global_moderators
  end
end
