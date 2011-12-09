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
  config.s3_access_key_id = Worlize.config['amazon']['access_key_id']
  config.s3_secret_access_key = Worlize.config['amazon']['secret_access_key']
end