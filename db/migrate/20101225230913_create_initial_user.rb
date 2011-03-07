class CreateInitialUser < ActiveRecord::Migration
  def self.up
    User.reset_column_information
    user = User.create(
      :username => 'worlize',
      :first_name => 'Worlize',
      :last_name => 'Worlize',
      :email => 'devtest@worlize.com',
      :birthday => 18.years.ago,
      :password => 'abcdefg',
      :password_confirmation => 'abcdefg',
      :admin => true
    )
    user.first_time_login
  end

  def self.down
    user = User.find_by_username('worlize')
    user.destroy
  end
end
