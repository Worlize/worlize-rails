class PaypalController < ApplicationController
#  include ActiveMerchant::Billing::Integrations

  layout "plain"
  skip_before_filter :verify_authenticity_token
  before_filter :require_user, :only => [:return]

#  def ipn
#    notification = Paypal::Notification.new(request.raw_post)
#    
#    # Verify that the IPN post actually came from Paypal.
#    if !notification.acknowledge
#      Rails.logger.error "Invalid/Forged Paypal IPN!  Raw post:\n#{request.raw_post}\nEND RAW POST"
#      render :nothing => true and return
#    end
#    
#    # See if the paypal transaction has already been handled
#    paypal_txn = PaypalTransaction.find_by_txn_id(notification.transaction_id)
#    if !paypal_txn.nil?
#      Rails.logger.info "Paypal IPN received for already processed txn_id."
#      render :nothing => true and return
#    end
#    
#    Payment.transaction do
#      
#      # Record the raw paypal notification
#      n = notification
#      paypal_txn = PaypalTransaction.new(
#        :txn_type => notification.type,
#        :txn_id => notification.transaction_id,
#        :custom_value => n.params['custom'],
#        :receipt_id => n.params['receipt_id'],
#        :address_country => n.params['address_country'],
#        :address_city => n.params['address_city'],
#        :address_country_code => n.params['address_country_code'],
#        :address_name => n.params['address_name'],
#        :address_state => n.params['address_state'],
#        :address_status => n.params['address_status'],
#        :address_street => n.params['address_street'],
#        :address_zip => n.params['address_zip'],
#        :contact_phone => n.params['contact_phone'],
#        :first_name => n.params['first_name'],
#        :last_name => n.params['last_name'],
#        :payer_business_name => n.params['payer_business_name'],
#        :payer_email => n.params['payer_email'],
#        :payer_id => n.params['payer_id'],
#        :auth_amount => n.params['auth_amount'],
#        :auth_id => n.params['auth_id'],
#        :auth_status => n.params['auth_status'],
#        :exchange_rate => n.params['exchange_rate'],
#        :invoice => n.params['invoice'],
#        :item_number => n.params['item_number'],
#        :mc_currency => n.params['mc_currency'],
#        :mc_fee => n.params['mc_fee'],
#        :mc_gross => n.params['mc_gross'],
#        :mc_handling => n.params['mc_handling'],
#        :mc_shipping => n.params['mc_shipping'],
#        :payer_paypal_account_verified => (n.params['payer_status'] == 'verified'),
#        :payment_date => n.received_at,
#        :payment_status => n.status,
#        :payment_type => n.params['payment_type'],
#        :pending_reason => n.params['pending_reason'],
#        :protection_eligibility => n.params['protection_eligibility'],
#        :quantity => n.params['quantity'],
#        :reason_code => n.params['reason_code'],
#        :remaining_settle => n.params['remaining_settle'],
#        :settle_amount => n.params['settle_amount'],
#        :settle_currency => n.params['settle_currency'],
#        :shipping => n.params['shipping'],
#        :shipping_method => n.params['shipping_method'],
#        :tax => n.params['tax'],
#        :transaction_entity => n.params['transaction_entity'],
#        :case_id => n.params['case_id'],
#        :case_type => n.params['case_type']
#      )
#      if (n.params['case_creation_date'])
#        paypal_txn.case_creation_date = Time.parse(n.params['case_creation_date'])
#      end
#      if (n.params['auth_exp'])
#        paypal_txn.auth_exp = Time.parse(n.params['auth_exp'])
#      end
#      # Make sure to save the paypal transaction record in the database
#      paypal_txn.save!
#
#      # Make sure the transaction is complete.. we only care about complete
#      # transactions after this point...
#      if !notification.complete?
#        Rails.logger.info "Non-Complete paypal transaction came in"
#        render :nothing => true and return
#      end
#      
#
#      # Find the specified virtual currency product
#      product = VirtualCurrencyProduct.find(notification.item_id)
#
#      # Make sure the price paid is what we expect
#      if product.price != BigDecimal.new(notification.gross)
#        Rails.logger.error "Paypal IPN amount (#{notification.gross}) doesn't match the specified product's price!!  Raw post:\n#{request.raw_post}\nEND RAW POST"
#        render :nothing => true and return
#      end
#
#      # Parse the JSON-encoded 'custom' field for the user guid
#      begin
#        custom = Yajl::Parser.parse(notification.params['custom'])
#      rescue
#        Rails.logger.error "Unable to parse JSON data from IPN 'custom' field.  Custom data: #{notification.params['custom']}"
#        render :nothing => true and return
#      end
#    
#      # Make sure we can find the specified user account
#      user = User.find_by_guid(custom['u'])
#      if user.nil?
#        Rails.logger.error "Unable to load the specified user account '#{custom['u']}' specified in the IPN."
#        render :nothing => true and return
#      end
#
#      Rails.logger.info "Found correct product and user for IPN!"
#    
#      # Record the payment and link it to the paypal transaction
#      payment = Payment.create!(
#        :user => user,
#        :paypal_transaction => paypal_txn,
#        :virtual_currency_product => product,
#        :amount => notification.gross,
#        :currency => notification.currency,
#        :comment => product.name
#      )
#      
#      Worlize.event_logger.info("action=payment_received amount=#{notification.gross} payment_type=paypal user=#{user.guid} user_username=\"#{user.username}\" paypal_txn=#{notification.transaction_id} virtual_currency_product_id=#{product.id}")
#    
#      if product.coins_to_add > 0 || product.bucks_to_add > 0
#        transaction = VirtualFinancialTransaction.new(
#          :user => user,
#          :payment => payment,
#          :virtual_currency_product => product,
#          :kind => VirtualFinancialTransaction::KIND_CREDIT_PURCHASE,
#          :comment => product.name
#        )
#        if product.coins_to_add > 0
#          transaction.coins_amount = product.coins_to_add
#        end
#        if product.bucks_to_add > 0
#          transaction.bucks_amount = product.bucks_to_add
#        end
#        transaction.save!
#
#        # Recalculate and cache coins & bucks balance in redis
#        user.recalculate_balances
#        user.notify_client_of_balance_change
#        user.send_message({
#          :msg => 'payment_completed'
#        })
#      end
#    end
#
#    render :nothing => true
#  end
  
  def return
    
  end

end
