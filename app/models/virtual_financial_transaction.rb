class VirtualFinancialTransaction < ActiveRecord::Base
  KIND_CREDIT_ADJUSTMENT        = 1
  KIND_CREDIT_PURCHASE          = 2
  KIND_DEBIT_ADJUSTMENT         = 101
  KIND_DEBIT_ITEM_PURCHASE      = 102
  KIND_DEBIT_SLOT_PURCHASE      = 103
  
  KINDS = {
    1   => "Credit Adjustment",
    2   => "Currency Purchase",
    101 => "Debit Adjustment",
    102 => "Product Purchase",
    103 => "Locker Storage Purchase"
  }
  
  validates :coins_amount, :numericality => { :only_integer => true }, :allow_nil => true
  validates :bucks_amount, :numericality => { :only_integer => true }, :allow_nil => true
  
  belongs_to :user
  belongs_to :marketplace_item
  belongs_to :payment
  belongs_to :virtual_currency_product
end
