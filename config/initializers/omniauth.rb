# Uncomment this, rename to omniauth.rb, and add the relevant key/secret information

Rails.application.config.middleware.use OmniAuth::Builder do
  if Worlize.config['twitter']
    options = {}
    if Rails.env == 'production'
      options[:client_options] = {:ssl => {:ca_path => '/etc/ssl/certs'}}
    end
    provider :twitter, Worlize.config['twitter']['app_id'], Worlize.config['twitter']['app_secret'], options
  end
  if Worlize.config['facebook']
    options = {
      :scope => Worlize.config['facebook']['requested_permissions']
    }
    if Rails.env == 'production'
      options[:client_options] = {:ssl => {:ca_path => '/etc/ssl/certs'}}
    end
    provider :facebook, Worlize.config['facebook']['app_id'], Worlize.config['facebook']['app_secret'], options
  end
end
