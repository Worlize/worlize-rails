class RemoveAboutFromMarketplaceCreators < ActiveRecord::Migration
  def up
    remove_column :marketplace_creators, :about
  end

  def down
    add_column :marketplace_creators, :about, :string
  end
end