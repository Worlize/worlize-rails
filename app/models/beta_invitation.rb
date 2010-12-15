class BetaInvitation < ActiveRecord::Base
  belongs_to :inviter, :class_name => 'User'
  
  validates :email, { :presence => true,
                      :email => true
                    }
  
  
  before_create :generate_invite_code
  
  private
  def generate_invite_code()
    self.invite_code = Guid.new.to_b62
  end
end
