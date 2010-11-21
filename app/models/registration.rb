class Registration < ActiveRecord::Base
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :email, { :presence => true,
                      :email => true,
                      :uniqueness => {
                        :message => "has already been used to sign up for a beta registration"
                      }
                    }
end
