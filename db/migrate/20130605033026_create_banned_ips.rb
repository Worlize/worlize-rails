class CreateBannedIps < ActiveRecord::Migration
  def change
    create_table :banned_ips do |t|
      t.references :user
      t.column :ip, 'integer unsigned'
      t.integer :created_by
      t.integer :updated_by
      t.text :reason
      t.timestamps
    end
    
    add_index :banned_ips, :ip, :unique => true
    add_index :users, :current_login_ip
  end
end