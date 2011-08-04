# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

# Create initial user
user = User.create(
  :username => 'worlize',
  :first_name => 'Worlize',
  :last_name => 'Worlize',
  :email => 'devtest@worlize.com',
  :birthday => 18.years.ago,
  :password => 'abcdefg',
  :password_confirmation => 'abcdefg',
  :admin => ['development','test'].include?(::Rails.env)
)
user.first_time_login

# Upload initial background
filedata = File.new("#{Rails.root}/config/assets/default_background.jpg", 'r')
Background.reset_column_information
new_background = Background.create!(:name => 'Default Background',
                  :image => filedata,
                  :creator => User.first,
                  :active => true,
                  :do_not_delete => true
                 )
Background.initial_world_background_guid = new_background.guid

# Create initial user's world
user.create_world


# Populate 'currencies' table
connection = ActiveRecord::Base.connection();
connection.execute <<-SQL
  INSERT INTO currencies SET id = '1', name = 'Bucks'
SQL
connection.execute <<-SQL
  INSERT INTO currencies SET id = '2', name = 'Coins'
SQL


# Create test virtual currency products
if ::Rails.env == 'development'
  VirtualCurrencyProduct.create(
    :name => "Greg's Super Deal!",
    :description => "Get more for less with Greg!  75% off, today only!",
    :coins_to_add => 15000,
    :bucks_to_add => 25,
    :price => 5.00
  )
  VirtualCurrencyProduct.create(
    :name => "10,000 Coins",
    :description => nil,
    :coins_to_add => 10000,
    :bucks_to_add => 0,
    :price => 10.00
  )
  VirtualCurrencyProduct.create(
    :name => "50 Bucks",
    :description => nil,
    :coins_to_add => 0,
    :bucks_to_add => 50,
    :price => 25.00
  )
end
