class CreateUserRestrictions < ActiveRecord::Migration
  def self.up
    create_table :user_restrictions do |t|
      t.string :name
      t.references :user
      t.references :world
      t.datetime :expires_at
      t.integer :created_by
      t.integer :updated_by
      t.timestamps
    end
    
    add_index :user_restrictions, [:world_id, :user_id, :expires_at]
    add_index :user_restrictions, [:user_id, :expires_at]
    add_index :user_restrictions, :expires_at
  end

  def self.down
    drop_table :user_restrictions
  end
end