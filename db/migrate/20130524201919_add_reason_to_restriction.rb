class AddReasonToRestriction < ActiveRecord::Migration
  def change
    add_column :user_restrictions, :reason, :string, :limit => 1024
  end
end