class UserSession < Authlogic::Session::Base
  
  # Manually defining to_key method to deal with this issue with AuthLogic
  # and Rails 3:
  # http://github.com/binarylogic/authlogic/issues/issue/101/#comment_142986
  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end
  
  def persisted?
    !new_record?
  end
  
end
