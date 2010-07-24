class BackgroundInstance < ActiveRecord::Base
  belongs_to :background
  belongs_to :user
  belongs_to :room
  
  before_create :assign_guid
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
