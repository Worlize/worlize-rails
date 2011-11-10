class AddLogTextToClientErrorLogItems < ActiveRecord::Migration
  def self.up
    add_column :client_error_log_items, :log_text, :text
  end

  def self.down
    remove_column :client_error_log_items, :log_text
  end
end