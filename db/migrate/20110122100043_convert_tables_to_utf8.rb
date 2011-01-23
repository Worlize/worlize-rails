class ConvertTablesToUtf8 < ActiveRecord::Migration
  def self.up
    if connection.adapter_name == 'MySQL'
      tables = %w{
        authentications
        beta_codes
        beta_invitations
        currencies
        gifts
        global_options
        marketplace_categories
        marketplace_creators
        marketplace_featured_items
        marketplace_items
        marketplace_purchase_records
        marketplace_themes
        public_worlds
        registrations
        rooms
        sessions
        taggings
        tags
        worlds
      }
    
      execute "ALTER DATABASE #{connection.current_database} CHARACTER SET utf8 COLLATE utf8_general_ci"
    
      tables.each do |table|
        execute "ALTER TABLE #{table} CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci"
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Migration Error: The migration to utf8 is irreversible")
  end
end
