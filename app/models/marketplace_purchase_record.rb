class MarketplacePurchaseRecord < ActiveRecord::Base
  belongs_to :user
  belongs_to :marketplace_item
  
  validates :user,
              :presence => true
  
  validates :marketplace_item,
              :presence => true
              
  validates :purchase_price,
              :numericality => {
                :greater_than_or_equal_to => 0
              }
  
  validates :currency_id,
              :inclusion => { :in => [1, 2] }
end
