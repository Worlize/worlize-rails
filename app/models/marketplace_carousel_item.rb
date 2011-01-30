class MarketplaceCarouselItem < ActiveRecord::Base
  acts_as_list :scope => :marketplace_category_id
  belongs_to :marketplace_category
  belongs_to :marketplace_featured_item
  
  scope :in_category, lambda { |category_id|
    if category_id.instance_of? MarketplaceCategory
      category_id = category_id.id
    end
    where(:marketplace_category_id => category_id)
  }
end
