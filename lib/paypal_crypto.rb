require 'openssl'
module PayPalWPSToolkit
  class EWPServices
    def self.encrypt_data(paypal_cert, my_business_cert, my_business_key, my_business_key_password, myparams  )     
      paypal_cert      = OpenSSL::X509::Certificate.new(paypal_cert)     
      my_business_cert = OpenSSL::X509::Certificate.new(my_business_cert)      
      my_business_key  = OpenSSL::PKey::RSA.new(my_business_key, my_business_key_password)   
      info = ""
      myparams.each_pair {|key,value| info << "#{key}=#{value}\n"}
      # Rails.logger.debug "Params to encrypt:\n#{info}"
      signedInfo       = OpenSSL::PKCS7::sign(my_business_cert, my_business_key, info, [], OpenSSL::PKCS7::BINARY)
      # Rails.logger.debug "Signed info:\n#{signedInfo}"
      encryptedOutput = OpenSSL::PKCS7::encrypt([paypal_cert], signedInfo.to_der, OpenSSL::Cipher::Cipher::new("DES3"), OpenSSL::PKCS7::BINARY)
      # Rails.logger.debug "Full encrypted output:\n#{encryptedOutput}"
      encryptedOutput
    end
    
    def self.encrypt_button(paypal_public_cert, my_business_ewp_cert, my_business_ewp_key, my_business_ewp_key_password, ewpparams)   
      encrypted = encrypt_data(paypal_public_cert, my_business_ewp_cert, my_business_ewp_key, my_business_ewp_key_password, ewpparams)       
    end
  end
end