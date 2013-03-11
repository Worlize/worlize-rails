class UserSession < Authlogic::Session::Base
  httponly true
  secure true
  
  before_destroy :force_client_logout
  
  def persisted?
    !new_record?
  end
  
  def force_client_logout
    self.user.send_message({
      :msg => 'logged_out', 
      :data => 'You have logged out.'
    })
  end
  
end
