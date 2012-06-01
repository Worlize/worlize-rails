class CreateApps < ActiveRecord::Migration
  def self.up
    create_table :apps, :force => true do |t|
      t.references :creator
      t.string :guid, :limit => 36
      t.string :name, :limit => 64
      t.string :tagline
      t.text :description
      t.text :help
      t.string :icon
      t.string :app
      t.integer :width, :limit => 8
      t.integer :height, :limit => 8
      t.boolean :active, :default => true
      t.timestamps
    end
    
    create_table :app_instances, :force => true do |t|
      t.string :guid, :limit => 36
      t.references :app
      t.references :user
      t.references :room
      t.references :gifter
      t.timestamps
    end
    
    add_column :users, :app_slots, :integer
    
    App.reset_column_information
    AppInstance.reset_column_information
    User.reset_column_information
    
    User.update_all("app_slots = '10000'")
    
    LockerSlotPrice.create(:slot_kind => 'app', :bucks_amount => 5)
    
    say_with_time("Copying app objects to the new apps table") do
      InWorldObject.where(:kind => 'app').find_each do |obj|
        app = App.new(
          :guid => obj.guid,
          :name => obj.name,
          :description => 'No Description.',
          :tagline => nil,
          :help => nil,
          :width => obj.width,
          :height => obj.height,
          :active => obj.active,
          :creator_id => obj.creator_id,
          :created_at => obj.created_at
        )
        app.save!
        ActiveRecord::Base.connection.execute("UPDATE `apps` SET `app`='app.swf' WHERE `apps`.`id` = #{app.id}")
        
        obj.instances.each do |oi|
          app_instance = AppInstance.create(
            :guid => oi.guid,
            :app_id => app.id,
            :user_id => oi.user_id,
            :gifter_id => oi.gifter_id,
            :room_id => oi.room_id,
            :created_at => oi.created_at
          )
          
          if !oi.room.nil?
            
          end
        end
      end
    end
    
    # Object.destroy_all(:kind => 'app')
  end

  def self.down
    remove_column :users, :app_slots
    drop_table :app_instances
    drop_table :apps
  end
end