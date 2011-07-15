class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :paypal_transaction
  belongs_to :virtual_currency_product
end
