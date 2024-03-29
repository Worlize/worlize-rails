class MarketplaceItem < ActiveRecord::Base
  belongs_to :marketplace_creator
  belongs_to :marketplace_category
  belongs_to :marketplace_theme
  belongs_to :item, :polymorphic => true
  has_many :marketplace_featured_items, :as => :featured_item, :dependent => :destroy
  has_many :virtual_financial_transactions, :dependent => :restrict
  has_many :marketplace_item_giveaways, :dependent => :destroy
  
  acts_as_taggable_on :tags
  
  attr_accessor :user_submission
  
  before_destroy :delete_actual_item
  before_save :sync_name_to_item
  
  scope :active, lambda {
    where(:on_sale => true, :archived => false)
  }
  
  scope :not_archived, lambda {
    where(:archived => false)
  }
  
  scope :archived, lambda {
    where(:archived => true)
  }
  
  scope :avatars, lambda {
    where(:item_type => 'Avatar')
  }
  
  scope :backgrounds, lambda {
    where(:item_type => 'Background')
  }
  
  scope :in_world_objects, lambda {
    where(:item_type => 'InWorldObject')
  }
  
  scope :props, lambda {
    where(:item_type => 'Prop')
  }
  
  scope :apps, lambda {
    where(:item_type => 'App')
  }
  
  validates :name,
              :presence => true,
              :if => lambda { self.on_sale? || self.user_submission }

  validates :description,
              :length => {
                :maximum => 2500
              }
              
  validates :marketplace_creator,
              :presence => true,
              :if => :on_sale?
  
  validates :item_id,
              :presence => true
  
  validates :marketplace_category,
              :presence => { :if => :on_sale? }
  
  validates :currency_id,
              :inclusion => { :in => [1,2] }

  validates :price,
              :presence => true,
              :numericality => {
                :only_integer => true,
                :greater_than_or_equal_to => 0
              },
              :if => lambda { self.on_sale? || self.user_submission }
  
  validates :on_sale,
              :exclusion => { :in => [true],
                              :message => "can not be selected if item is archived."},
              :if => :archived?
  
  validate :must_not_be_featured_to_take_off_sale

  private
  
  def must_not_be_featured_to_take_off_sale
    if !self.on_sale? && self.marketplace_featured_items.where(:active => true).count > 0
      errors.add(:base, "You cannot take an item off-sale until there are no active featured items referencing it.")
    end
  end
  
  def delete_actual_item
    # If nobody has this item, delete the actual item too.
    if self.item.instances.count == 0
      self.item.destroy
    end
  end
  
  def sync_name_to_item
    if self.item
      self.item.update_attribute(:name, self.name)
    end
    
    if self.item && self.item.respond_to?('description')
      self.item.update_attribute(:description, self.description)
    end
  end
  
end
