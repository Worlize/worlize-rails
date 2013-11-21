class AddFingerPrintToImageAssetTables < ActiveRecord::Migration
  def change
    create_table :image_fingerprints, :force => true do |t|
      t.references :fingerprintable, :polymorphic => true, :null => false
      t.column :fingerprint, 'bigint unsigned', :null => false
    end
    add_index :image_fingerprints, [:fingerprintable_type, :fingerprintable_id], :unique => true, :name => 'fingerprintable_index'
  end
end
