class User < ActiveRecord::Base
  before_create :assign_guid
  has_many :worlds
  
  acts_as_authentic do |c|
    #config options here
  end
  
  def interactivity_session
    InteractivitySession.find_by_user_guid(self.guid)
  end
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
end
