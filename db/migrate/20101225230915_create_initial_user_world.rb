class CreateInitialUserWorld < ActiveRecord::Migration
  def self.up
    user = User.find_by_username('worlize')
    user.create_world
  end

  def self.down
  end
end
