class Registration < ActiveRecord::Base
  validates :name, :presence => true
  validates :email, { :presence => true,
                      :email => true,
                      :uniqueness => {
                        :message => "has already been used to sign up for a beta registration"
                      }
                    }
end
