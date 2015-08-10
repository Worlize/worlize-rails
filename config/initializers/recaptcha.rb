Recaptcha.configure do |config|
  config.public_key  = Worlize.config['recaptcha']['site_key']
  config.private_key = Worlize.config['recaptcha']['secret_key']
  config.api_version = 'v2'
end
