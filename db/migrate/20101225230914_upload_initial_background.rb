class UploadInitialBackground < ActiveRecord::Migration
  def self.up
    filedata = File.new("#{Rails.root}/config/assets/default_background.jpg", 'r')
    new_background = Background.create(:name => 'Default Background',
                      :image => filedata,
                      :return_coins => 0,
                      :sale_bucks => 0, 
                      :sale_coins => 0,
                      :creator => User.first,
                      :do_not_delete => true
                     )
    Background.initial_world_background_guid = new_background.guid
  end

  def self.down
  end
end
