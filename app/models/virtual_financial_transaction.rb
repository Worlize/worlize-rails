class VirtualFinancialTransaction < ActiveRecord::Base
  KIND_CREDIT_ADJUSTMENT        = 1
  KIND_CREDIT_PURCHASE          = 2
  KIND_CREDIT_CURRENCY_PURCHASE = 3
  KIND_DEBIT_ADJUSTMENT         = 101
  KIND_DEBIT_ITEM_PURCHASE      = 102
  
  belongs_to :user
  belongs_to :marketplace_item
end
