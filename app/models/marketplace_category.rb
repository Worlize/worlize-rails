class MarketplaceCategory < ActiveRecord::Base
  acts_as_tree :order => 'position, name'
  acts_as_list :scope => :parent_id
  
  has_many :marketplace_featured_items, :order => 'position', :dependent => :destroy
  has_many :marketplace_items, :order => 'created_at DESC', :dependent => :nullify
  has_many :marketplace_carousel_items, :order => 'position', :dependent => :destroy
  belongs_to :marketplace_theme
  
  validates :name,
              :presence => true
              
  def breadcrumbs
    category = self
    breadcrumbs = []
    while category.parent
      breadcrumbs.unshift(category)
      category = category.parent
    end
    breadcrumbs.unshift(category)
    return breadcrumbs
  end
  
  def name_with_breadcrumbs
    names = breadcrumbs.map { |category| category.name }
    names.join(': ')
  end
end
