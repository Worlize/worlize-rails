class PropInstance < ActiveRecord::Base
  belongs_to :prop
  belongs_to :user
  
  before_create :assign_guid
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
