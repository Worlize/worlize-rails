class VirtualCurrencyProductsController < ApplicationController
  before_filter :require_user
  layout "plain"

  def index
    @products = VirtualCurrencyProduct.where(:archived => false).order(:position)

    @encrypted = Hash.new
    @products.each do |product|
      @encrypted[product.id] = PayPalWPSToolkit::EWPServices.encrypt_button(
        Worlize::PaypalConfig.paypal_public_cert,
        Worlize::PaypalConfig.app_public_cert,
        Worlize::PaypalConfig.app_private_key,
        '',
        {
          :cmd => '_xclick',
          :charset => 'UTF-8',
          :currency_code => 'USD',
          :custom => Yajl::Encoder.encode(
            {
              # Short key names here.. we have 255 chars max.
              :u => current_user.guid
            }
          ),
          :cert_id => Worlize.config['paypal']['cert_id'],
          :business => Worlize.config['paypal']['business_email'],
          :item_number => product.id,
          :item_name => product.name,
          :amount => sprintf('%.2f', product.price),
          :return => paypal_return_url,
        }
      )
    end
  end
  
end
