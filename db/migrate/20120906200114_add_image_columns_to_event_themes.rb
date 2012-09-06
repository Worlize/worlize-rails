class AddImageColumnsToEventThemes < ActiveRecord::Migration
  def change
    add_column :event_themes, :thumbnail, :string
    add_column :event_themes, :header_image, :string
    add_column :event_themes, :header_background, :string
  end
end