class PropInstance < ActiveRecord::Base
  belongs_to :prop
  belongs_to :user
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user
  
  def hash_for_api
    {
      :prop => self.prop.hash_for_api,
      :guid => self.guid,
      :user_guid => self.user.guid
    }
  end
  
  private
  def notify_user
    if self.user
      self.user.send_message({
        :msg => 'new_prop_instance',
        :data => self.hash_for_api
      })
    end
  end
    
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
