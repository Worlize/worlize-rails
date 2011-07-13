class PaypalController < ApplicationController
  include ActiveMerchant::Billing::Integrations

  skip_before_filter :verify_authenticity_token

  def ipn
    notification = Paypal::Notification.new(request.raw_post)
    
    if notification.acknowledge
      
      # Find the specified virtual currency product
      product = VirtualCurrencyProduct.find(notification.item_id)
      
      if notification.complete?
        if product.price == notification.gross.to_f
          
          # begin
            custom = Yajl::Parser.parse(notification.params['custom'])
          # rescue
          #   Rails.logger.error "Unable to parse JSON data from IPN 'custom' field.  Custom data: #{notification.params['custom']}"
          #   return
          # end
          
          user = User.find_by_guid(custom['user'])
          
          if user
            
            Rails.logger.info "Found correct product and user for IPN!"
            
            render :nothing => true and return
            
          else
            Rails.logger.error "Unable to load the specified user account '#{custom['user']}' specified in the IPN."
          end
          
        else
          Rails.logger.error "Paypal IPN amount (#{notification.gross}) doesn't match the specified product's price!!  Raw post:\n#{request.raw_post}"
        end
      end
      
    else
      Rails.logger.error "Invalid Paypal IPN!  Raw post:\n#{request.raw_post}"
    end
    
    render :nothing => true
  end
  
  def return
    
  end

end
