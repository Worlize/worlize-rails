class VirtualFinancialTransaction < ActiveRecord::Base
  KIND_CREDIT_ADJUSTMENT        = 1
  KIND_CREDIT_PURCHASE          = 2
  KIND_DEBIT_ADJUSTMENT         = 101
  KIND_DEBIT_ITEM_PURCHASE      = 102
  
  KINDS = {
    1   => "Credit Adjustment",
    2   => "Currency Purchase",
    101 => "Debit Adjustment",
    102 => "Product Purchase"
  }
  
  belongs_to :user
  belongs_to :marketplace_item
  belongs_to :payment
end
