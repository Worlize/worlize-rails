class AddNewsletterOptInToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :newsletter_optin, :boolean, :default => true
  end

  def self.down
    remove_column :users, :newsletter_optin
  end
end