CarrierWave.configure do |config|
  config.s3_access_key_id = Worlize.config['amazon']['access_key_id']
  config.s3_secret_access_key = Worlize.config['amazon']['secret_access_key']
end