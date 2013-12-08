class AddAboutToMarketplaceCreators < ActiveRecord::Migration
  def change
    add_column :marketplace_creators, :about, :text
  end
end
