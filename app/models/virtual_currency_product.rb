class VirtualCurrencyProduct < ActiveRecord::Base
  before_create :assign_guid
  
  acts_as_list :scope => 'archived = 0'
  
  validates :coins_to_add, :numericality => {
    :greater_than_or_equal_to => 0
  }
  validates :bucks_to_add, :numericality => {
    :greater_than_or_equal_to => 0
  }
  validates :price, :numericality => {
    :greater_than => 0
  }
  validates :name, :presence => true
  validates :description, :length => {
    :maximum => 500
  }
  
  private
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
