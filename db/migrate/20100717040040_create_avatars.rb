class CreateAvatars < ActiveRecord::Migration
  def self.up
    create_table :avatars, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string :guid, :limit => 36
      t.references :creator
      t.string :name, :limit => 64
      t.integer :offset_x, :limit => 5
      t.integer :offset_y, :limit => 5
      t.integer :width, :limit => 5
      t.integer :height, :limit => 5
      t.boolean :active, :default => true
      t.integer :price, :limit => 11
      t.string :image
      t.timestamps
    end
    add_index :avatars, :guid
  end

  def self.down
    remove_index :avatars, :guid
    drop_table :avatars
  end
end


# +--------------------+------------------+------+-----+---------------+-------+
# | Field              | Type             | Null | Key | Default       | Extra |
# +--------------------+------------------+------+-----+---------------+-------+
# | guid               | char(36)         | NO   | PRI | NULL          |       | 
# | originating_palace | varchar(255)     | NO   |     |               |       | 
# | legacy_id          | int(11)          | YES  | MUL | NULL          |       | 
# | legacy_crc         | int(11) unsigned | YES  |     | NULL          |       | 
# | offset_x           | int(5)           | NO   |     | 0             |       | 
# | offset_y           | int(5)           | NO   |     | 0             |       | 
# | width              | int(5)           | NO   |     | 44            |       | 
# | height             | int(5)           | NO   |     | 44            |       | 
# | flag_head          | tinyint(1)       | NO   |     | 0             |       | 
# | flag_ghost         | tinyint(1)       | NO   |     | 0             |       | 
# | flag_rare          | tinyint(1)       | NO   |     | 0             |       | 
# | flag_animate       | tinyint(1)       | NO   |     | 0             |       | 
# | flag_palindrome    | tinyint(1)       | NO   |     | 0             |       | 
# | flag_bounce        | tinyint(1)       | NO   |     | 0             |       | 
# | format             | varchar(16)      | NO   |     | png           |       | 
# | name               | varchar(255)     | NO   |     | Untitled Prop |       | 
# | active             | tinyint(1)       | NO   |     | 0             |       | 
# | created            | datetime         | NO   | MUL | NULL          |       | 
# | last_modified      | datetime         | NO   | MUL | NULL          |       | 
# | added_by_user_guid | char(36)         | NO   |     | NULL          |       | 
# +--------------------+------------------+------+-----+---------------+-------+
