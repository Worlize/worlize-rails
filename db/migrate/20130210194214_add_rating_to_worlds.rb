class AddRatingToWorlds < ActiveRecord::Migration
  def up
    add_column :worlds, :rating, :string, :default => 'Not Rated'
    execute <<-eof
      UPDATE `worlds` SET `rating` = 'Not Rated'
    eof
  end
  
  def down
    remove_column :worlds, :rating
  end
end
