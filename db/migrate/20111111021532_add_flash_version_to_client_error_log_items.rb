class AddFlashVersionToClientErrorLogItems < ActiveRecord::Migration
  def self.up
    add_column :client_error_log_items, :flash_version, :string
  end

  def self.down
    remove_column :client_error_log_items, :flash_version
  end
end