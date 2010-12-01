class BackgroundInstance < ActiveRecord::Base
  belongs_to :background
  belongs_to :user
  belongs_to :room
  
  before_create :assign_guid
  
  def hash_for_api
    {
      :background => self.background.hash_for_api,
      :guid => self.guid,
      :room => self.room ? {
        :name => self.room.name,
        :guid => self.room.guid
      } : nil,
      :user_guid => self.user.guid
    }
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
