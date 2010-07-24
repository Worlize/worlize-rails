class WelcomeController < ApplicationController
  layout "prelaunch"
  
  before_filter :require_user, :only => [:enter]
  
  def index
    @registration = Registration.new
    @developerRegistration = Registration.new
  end
  
  def enter
    @configJSON = Yajl::Encoder.encode({
      "userGuid" => current_user.guid,
      "sessionGuid" => current_user.interactivity_session.guid,
      "userName" => current_user.username,
      "authenticityToken" => form_authenticity_token
    })
    render :enter, :layout => false
  end
end
