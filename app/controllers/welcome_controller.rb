class WelcomeController < ApplicationController
  layout "prelaunch"
  
  before_filter :require_user, :only => [:enter]
  
  def index
    @registration = Registration.new
    @developerRegistration = Registration.new
  end
  
  def enter
    @configJSON = Yajl::Encoder.encode({
      "user_guid" => current_user.guid,
      "username" => current_user.username,
      "admin" => current_user.admin?,
      "interactivity_session" => current_user.interactivity_session.serializable_hash,
      "authenticity_token" => form_authenticity_token,
      "cookies" => cookies
    })
    render :enter, :layout => false
  end
end
