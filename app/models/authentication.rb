class Authentication < ActiveRecord::Base
  belongs_to :user
  validates :uid, :uniqueness => { :scope => :provider }
  
  after_create :log_creation
  after_destroy :log_destruction
  
  private
  
  def log_creation
    Worlize.event_logger.info("action=external_authentication_created provider=#{self.provider} user=#{self.user.guid} user_username=\"#{self.user.username}\" provider_uid=#{self.uid}")
  end
  
  def log_destruction
    Worlize.event_logger.info("action=external_authentication_destroyed provider=#{self.provider} user=#{self.user.guid} user_username=\"#{self.user.username}\" provider_uid=#{self.uid}")
  end
end
