class WelcomeController < ApplicationController
  
  before_filter :require_user, :only => [:enter]
  
  def index
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
    current_user.disable_webcam!
    
    @configJSON = Yajl::Encoder.encode({
      'marketplace_enabled' => Worlize.config['marketplace_enabled'],
      'marketplace' => Worlize.config['marketplace'],
      'user_guid' => current_user.guid,
      'username' => current_user.username,
      'admin' => current_user.admin?,
      'current_user' => current_user.hash_for_api,
      'interactivity_session' => current_user.interactivity_session.serializable_hash,
      'authenticity_token' => form_authenticity_token,
      'cookies' => cookies,
      'interactivity_hostname' => Worlize.config['interactivity_hostname'],
      'interactivity_port' => request.ssl? ? 443 : 80,
      'interactivity_tls' => request.ssl?
    })
    current_user.send_message({
      :msg => 'logged_out', 
      :data => 'You have signed on from another location.'
    })
    render :enter, :layout => false
  end

end
