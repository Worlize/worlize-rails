class AdjustSizeOfDescriptionField < ActiveRecord::Migration
  def self.up
    change_column :marketplace_items, :description, :text
    change_column :marketplace_themes, :css, :text
  end

  def self.down
    change_column :marketplace_themes, :css, :text
    change_column :marketplace_items, :description, :text
  end
end
