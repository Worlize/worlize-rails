class PropInstance < ActiveRecord::Base
  belongs_to :prop
  belongs_to :user
  belongs_to :gifter, :class_name => 'User'
  
  before_create :assign_guid
  after_create :notify_user_of_creation
  after_destroy :notify_user_of_deletion
  
  def hash_for_api
    {
      :prop => self.prop.hash_for_api,
      :guid => self.guid,
      :user_guid => self.user.guid,
      :gifter => self.gifter.nil? ? nil : self.gifter.public_hash_for_api
    }
  end
  
  private
  def notify_user_of_creation
    if self.user
      self.user.send_message({
        :msg => 'prop_instance_added',
        :data => self.hash_for_api
      })
    end
  end
  
  def notify_user_of_deletion
    if self.user
      self.user.send_message({
        :msg => 'prop_instance_deleted',
        :data => { :guid => self.guid }
      })
    end
  end
    
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end
