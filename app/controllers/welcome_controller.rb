class WelcomeController < ApplicationController
  layout "prelaunch"
  
  before_filter :require_user, :only => [:enter]
  
  def index
    @registration = Registration.new
    @developerRegistration = Registration.new
  end
  
  def enter
    session_key_name = Rails.application.config.session_options[:key]
    @configJSON = Yajl::Encoder.encode({
      "session_key" => session_key_name,
      "session_token" => cookies[session_key_name],
      "user_guid" => current_user.guid,
      "username" => current_user.username,
      "interactivity_session" => current_user.interactivity_session.serializable_hash,
      "authenticity_token" => form_authenticity_token,
      "cookies" => cookies
    })
    render :enter, :layout => false
  end
end
