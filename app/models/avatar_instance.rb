class AvatarInstance < ActiveRecord::Base
  belongs_to :avatar
  belongs_to :user
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user
  
  def hash_for_api
    {
      :avatar => self.avatar.hash_for_api,
      :guid => self.guid,
      :user_guid => self.user.guid,
      :gifter => self.gifter.nil? ? nil : self.gifter.public_hash_for_api
    }
  end
  
  
  private
  def notify_user
    if self.user
      self.user.send_message({
        :msg => 'avatar_instance_added',
        :data => self.hash_for_api
      })
    end
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
