class MarketplaceCarouselItem < ActiveRecord::Base
  acts_as_list :scope => :marketplace_category_id
  belongs_to :marketplace_category
  belongs_to :marketplace_featured_item
  
  scope :active, lambda {
    joins(:marketplace_featured_item).
    where("#{connection.quote_table_name("marketplace_featured_items")}.#{connection.quote_column_name("active")} = ?", true)
  }
  
  scope :in_category, lambda { |category_id|
    if category_id.instance_of? MarketplaceCategory
      category_id = category_id.id
    end
    where(:marketplace_category_id => category_id)
  }
end
