class MarketplaceItemGiveawayReceipt < ActiveRecord::Base
  belongs_to :user
  belongs_to :marketplace_item_giveaway
  
  scope :for_promo_program, lambda { |promo_program|
    id = promo_program.kind_of?(Fixnum) ? promo_program : promo_program.id
    joins(:marketplace_item_giveaway => :promo_program).
    where(['`promo_programs`.`id` = ?', id])
  }
  
  scope :for_date, lambda { |date|
    joins(:marketplace_item_giveaway).
    where(['`marketplace_item_giveaways`.`date` = ?', date])
  }
end
