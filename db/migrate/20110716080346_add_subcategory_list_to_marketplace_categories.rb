class AddSubcategoryListToMarketplaceCategories < ActiveRecord::Migration
  def self.up
    add_column :marketplace_categories, :subcategory_list, :string, :default => ''
    
    MarketplaceCategory.reset_column_information
    
    MarketplaceCategory.all.each do |category|
      category.update_subcategory_list!
    end
  end

  def self.down
    remove_column :marketplace_categories, :subcategory_list
  end
end
