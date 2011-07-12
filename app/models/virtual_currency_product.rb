class VirtualCurrencyProduct < ActiveRecord::Base
  before_create :assign_guid
  
  acts_as_list
  
  
  private
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
