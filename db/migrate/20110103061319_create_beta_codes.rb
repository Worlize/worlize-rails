class CreateBetaCodes < ActiveRecord::Migration
  def self.up
    create_table :beta_codes do |t|
      t.string :code
      t.integer :signups_allotted
      t.string :campaign_name
      t.timestamps
    end
    add_index :beta_codes, :code
  end

  def self.down
    remove_index :beta_codes, :code
    drop_table :beta_codes
  end
end
