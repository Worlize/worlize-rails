class CreateLockerSlotPrices < ActiveRecord::Migration
  def self.up
    create_table :locker_slot_prices do |t|
      t.string :slot_kind
      t.integer :bucks_amount
      t.timestamps
    end
    
    LockerSlotPrice.reset_column_information
    
    LockerSlotPrice.create(:slot_kind => 'avatar', :bucks_amount => 3)
    LockerSlotPrice.create(:slot_kind => 'in_world_object', :bucks_amount => 5)
    LockerSlotPrice.create(:slot_kind => 'background', :bucks_amount => 20)
    LockerSlotPrice.create(:slot_kind => 'prop', :bucks_amount => 3)
  end

  def self.down
    drop_table :locker_slot_prices
  end
end
