class MarketplaceItem < ActiveRecord::Base
  belongs_to :marketplace_creator
  belongs_to :marketplace_category
  belongs_to :marketplace_theme
  belongs_to :item, :polymorphic => true
  has_many :featured_items, :class_name => 'MarketplaceFeaturedItem'
  has_many :purchase_records, :class_name => 'MarketplacePurchaseRecord'
  
  acts_as_taggable_on :tags
  
  validates :name,
              :presence => true

  validates :description,
              :length => {
                :minimum => 0,
                :maximum => 2500
              }
  
  validates :currency_id,
              :inclusion => { :in => [1,2] }

  validates :price,
              :presence => true,
              :numericality => {
                :only_integer => true,
                :greater_than_or_equal_to => 0
              }
  
end
