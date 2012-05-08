class AppInstance < ActiveRecord::Base
  belongs_to :app
  belongs_to :user
  belongs_to :room
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user
  
  def hash_for_api
    {
      :app => self.app.hash_for_api,
      :room => self.room ? self.room.basic_hash_for_api : nil,
      :guid => self.guid
    }
  end
  
  private
  def notify_user
    if self.user
      self.user.send_message({
        :msg => 'app_instance_added',
        :data => self.hash_for_api
      })
    end
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s if self.guid.nil?
  end
  
end
