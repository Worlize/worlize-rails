class AvatarInstance < ActiveRecord::Base
  belongs_to :avatar
  belongs_to :user
  
  before_create :assign_guid
  
  def hash_for_api
    {
      :avatar => self.avatar.hash_for_api,
      :guid => self.guid,
      :user_guid => self.user.guid
    }
  end
  
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
