class CreateUserProfiles < ActiveRecord::Migration
  def up
    create_table :user_profiles, :force => true do |t|
      t.references  :user
      t.string      :cover_image
      t.string      :profile_image
      t.text        :about
      t.timestamps
    end
  end

  def down
    drop_table :user_profiles
  end
end