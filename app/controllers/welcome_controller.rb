class WelcomeController < ApplicationController
  
  before_filter :require_user, :only => [:enter]
  
  def index
    if current_user
      redirect_to dashboard_url and return
    end
    
    @user_session = UserSession.new
    characters = {
      'halbert' => 'I am HAL(bert).  Identify yourself!',
      'gus' => 'They call me Guss... What do they call you?',
      'jules' => 'I\'m jules... what\'s YOUR name?',
      'neo' => 'Neo is the name... Are you plugged in?',
      'sam' => 'sam, I am... and you?',
      'sunny' => 'I\'m sunny... with a chance of rain.'
    }
    
    character_names = characters.keys
    @character_name = character_names[rand(character_names.length)]
    @saying = characters[@character_name]
  end
  
  def about
    
  end
  
  def enter
    @configJSON = Yajl::Encoder.encode({
      'marketplace_enabled' => Worlize.config['marketplace_enabled'],
      'user_guid' => current_user.guid,
      'username' => current_user.username,
      'admin' => current_user.admin?,
      'interactivity_session' => current_user.interactivity_session.serializable_hash,
      'authenticity_token' => form_authenticity_token,
      'cookies' => cookies
    })
    render :enter, :layout => false
  end

end
