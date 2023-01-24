module Worlize
  module PaypalConfig
    def self.paypal_public_cert
      @paypal_public_cert ||= File.read(File.join(Rails.root, Worlize.config['paypal']['paypal_public_cert_file']))
    end
    
    def self.app_public_cert
      @app_public_cert ||= File.read(File.join(Rails.root, Worlize.config['paypal']['app_public_cert_file']))
    end
    
    def self.app_private_key
      @app_private_key ||= File.read(File.join(Rails.root, Worlize.config['paypal']['app_private_key_file']))
    end
  end
end

unless ::Rails.env == 'production'
#  ActiveMerchant::Billing::Base.mode = :test
end
