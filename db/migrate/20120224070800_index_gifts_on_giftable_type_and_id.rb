class IndexGiftsOnGiftableTypeAndId < ActiveRecord::Migration
  def self.up
    add_index :gifts, ['giftable_type','giftable_id']
  end

  def self.down
    remove_index :gifts, ['giftable_type','giftable_id']
  end
end