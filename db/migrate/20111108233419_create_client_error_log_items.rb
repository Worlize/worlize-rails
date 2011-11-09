class CreateClientErrorLogItems < ActiveRecord::Migration
  def self.up
    create_table :client_error_log_items do |t|
      t.column :user_id, :string
      t.column :error_type, :string
      t.column :error_id, :integer
      t.column :name, :string
      t.column :message, :string
      t.column :stack_trace, :text
      t.timestamps
    end
  end

  def self.down
    drop_table :client_error_log_items
  end
end
