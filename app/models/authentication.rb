class Authentication < ActiveRecord::Base
  belongs_to :user
  validates :uid, :uniqueness => { :scope => :provider }
  
  after_create :notify_user_of_creation, :log_creation
  after_destroy :notify_user_of_destruction, :log_destruction
  
  def hash_for_api
    {
      :provider => provider,
      :uid => uid,
      :created_at => created_at,
      :token => token,
      :profile_url => profile_url,
      :display_name => display_name,
      :profile_picture => profile_picture
    }
  end
  
  private
  
  def notify_user_of_destruction
    user.send_message({
      :msg => "linked_profile_removed",
      :data => hash_for_api
    })
  end
  
  def notify_user_of_creation
    user.send_message({
      :msg => "linked_profile_added",
      :data => hash_for_api
    })
  end
  
  def log_creation
    Worlize.event_logger.info("action=external_authentication_created provider=#{self.provider} user=#{self.user.guid} user_username=\"#{self.user.username}\" provider_uid=#{self.uid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=external_authentication_destroyed provider=#{self.provider} user=#{self.user.guid} user_username=\"#{self.user.username}\" provider_uid=#{self.uid}")
  end
end
