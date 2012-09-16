class RenameEventOrderToPosition < ActiveRecord::Migration
  def up
    rename_column :event_room_options, :order, :position
    rename_column :event_themes, :order, :position
    rename_column :event_categories, :order, :position
  end

  def down
    rename_column :event_room_options, :position, :order
    rename_column :event_themes, :position, :order
    rename_column :event_categories, :position, :order
  end
end
