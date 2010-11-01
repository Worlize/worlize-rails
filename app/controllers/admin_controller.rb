class AdminController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  def index
    @user_count = User.count;
    @registration_count = Registration.count;
  end

end
