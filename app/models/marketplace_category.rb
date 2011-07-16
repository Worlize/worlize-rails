class MarketplaceCategory < ActiveRecord::Base
  acts_as_tree :order => 'position, name'
  acts_as_list :scope => :parent_id
  
  has_many :marketplace_featured_items, :order => 'position', :dependent => :destroy
  has_many :marketplace_items, :order => 'created_at DESC', :dependent => :nullify
  has_many :marketplace_carousel_items, :order => 'position', :dependent => :destroy
  belongs_to :marketplace_theme
  
  after_update :update_old_parent_subcategory_lists!
  after_save :update_parent_subcategory_lists!
  after_destroy :update_parent_subcategory_lists!
  
  validates :name,
              :presence => true
              
  def descends_from?(ancestor)
    ancestor = ancestor.id if ancestor.instance_of? MarketplaceCategory
    category = self
    while category
      return true if category.parent_id == ancestor
      category = category.parent
    end
    return false
  end
  
  def build_subcategory_list
    return @list if @list
    @list = []
    children.each do |child|
      @list.push(child.id)
      @list.concat(child.build_subcategory_list)
    end
    return @list
  end
  
  def populate_subcategory_list
    subcategory_list = build_subcategory_list
  end
  
  def update_subcategory_list!
    update_attribute('subcategory_list', build_subcategory_list.join(','))
  end
  
  def update_parent_subcategory_lists!
    current_category = self
    while current_category.parent_id
      current_category = MarketplaceCategory.find(current_category.parent_id)
      current_category.update_subcategory_list!
    end
  end
  
  def update_old_parent_subcategory_lists!
    if parent_id_changed?
      previous_category = MarketplaceCategory.find(parent_id_was)
      previous_category.update_subcategory_list!
      previous_category.update_parent_subcategory_lists!
    end
  end
  
  def breadcrumbs
    return @breadcrumbs if @breadcrumbs
    category = self
    @breadcrumbs = []
    while category.parent
      @breadcrumbs.unshift(category)
      category = category.parent
    end
    @breadcrumbs.unshift(category)
    return @breadcrumbs
  end
  
  def name_with_breadcrumbs
    names = breadcrumbs.map { |category| category.name }
    names.join(': ')
  end
end
