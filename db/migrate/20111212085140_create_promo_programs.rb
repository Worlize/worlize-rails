class CreatePromoPrograms < ActiveRecord::Migration
  def self.up
    create_table :promo_programs do |t|
      t.string :name
      t.date :start_date
      t.date :end_date
      t.text :dialog_css
      t.string :mode
      t.timestamps
    end
  end

  def self.down
    drop_table :promo_programs
  end
end
