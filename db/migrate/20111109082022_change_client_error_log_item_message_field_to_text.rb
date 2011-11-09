class ChangeClientErrorLogItemMessageFieldToText < ActiveRecord::Migration
  def self.up
    change_column :client_error_log_items, :message, :text
  end

  def self.down
    change_column :client_error_log_items, :message, :string
  end
end