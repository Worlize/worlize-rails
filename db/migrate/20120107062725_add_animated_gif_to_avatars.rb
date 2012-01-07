class AddAnimatedGifToAvatars < ActiveRecord::Migration
  def self.up
    add_column :avatars, :animated_gif, :boolean, :default => false
  end

  def self.down
    remove_column :avatars, :animated_gif
  end
end