class MarketplaceItemGiveaway < ActiveRecord::Base
  belongs_to :marketplace_item
  belongs_to :promo_program
  has_many :marketplace_item_giveaway_receipts, :dependent => :destroy  

  scope :active, lambda {
    where(['date >= ?', Time.current.to_date])
  }
  
  scope :for_today, lambda {
    where(['date = ?', Time.current.to_date])
  }
  
  validates :promo_program, :presence => true
  validates :name, :presence => true
  validates :date, :presence => true

end
