class CreateBannedImageFingerprints < ActiveRecord::Migration
  def change
    create_table :banned_image_fingerprints do |t|
      t.column :dct_fingerprint, 'bigint unsigned', :null => false
      t.timestamps
    end
    
    add_index :banned_image_fingerprints, :dct_fingerprint
  end
end