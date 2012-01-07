if Worlize.config.nil?
  require 'application_config.rb'
end

module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.quality(percentage)
        img = yield(img) if block_given?
        img
      end
    end
  end
end

CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider => 'AWS',
    :aws_access_key_id => Worlize.config['amazon']['access_key_id'],
    :aws_secret_access_key => Worlize.config['amazon']['secret_access_key']
  }
  config.fog_attributes = {
    'Cache-Control' => 'max-age=2592000',
    'Expires' => 'Sun, 17 Jan 2038 19:14:07 GMT'
  }
end