class CreateGifts < ActiveRecord::Migration
  def self.up
    create_table :gifts do |t|
      t.column :giftable_type, :string
      t.column :giftable_id, :integer
      t.column :sender_id, :integer
      t.column :recipient_id, :integer
      t.column :note, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :gifts
  end
end
