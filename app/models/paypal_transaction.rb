class PaypalTransaction < ActiveRecord::Base
  has_one :payment
end
