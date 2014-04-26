class AddMarketplaceCreatorProfileFields < ActiveRecord::Migration
  def change
    add_column :marketplace_creators, :about, :text
    add_column :marketplace_creators, :first_name, :string
    add_column :marketplace_creators, :last_name, :string
    add_column :marketplace_creators, :address1, :string
    add_column :marketplace_creators, :address2, :string
    add_column :marketplace_creators, :city, :string
    add_column :marketplace_creators, :state, :string
    add_column :marketplace_creators, :zipcode, :string
    add_column :marketplace_creators, :phone, :string
  end
end