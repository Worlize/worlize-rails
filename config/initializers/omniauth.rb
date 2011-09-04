# Uncomment this, rename to omniauth.rb, and add the relevant key/secret information

Rails.application.config.middleware.use OmniAuth::Builder do
  if Worlize.config['twitter']
    provider :twitter, Worlize.config['twitter']['app_id'], Worlize.config['twitter']['app_secret']
  end
  if Worlize.config['facebook']
    provider :facebook, Worlize.config['facebook']['app_id'], Worlize.config['facebook']['app_secret'], {
      :scope => 'email'
    }
  end
end
