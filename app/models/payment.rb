class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :paypal_transaction
end
