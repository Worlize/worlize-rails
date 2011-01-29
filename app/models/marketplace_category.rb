class MarketplaceCategory < ActiveRecord::Base
  acts_as_tree :order => 'position, name'
  acts_as_list :scope => :parent_id
  
  has_many :marketplace_featured_items, :dependent => :destroy
  has_many :marketplace_items, :dependent => :nullify
  belongs_to :marketplace_theme
  
  validates :name,
              :presence => true
end
