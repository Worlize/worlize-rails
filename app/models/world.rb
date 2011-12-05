class World < ActiveRecord::Base
  before_create :assign_guid

  belongs_to :user
  has_many :rooms, :dependent => :destroy
  has_one :public_world, :dependent => :destroy
  
  validates :name, :presence => true

  def basic_hash_for_api
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api
    }
  end

  def hash_for_api(current_user=nil)
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api,
      :can_create_new_room => current_user == self.user,
      :rooms => self.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => room.user_count
        }
      end
    }
  end
  
  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.world(:name => self.name) {
        self.rooms.each do |room|
          room.build_xml(xml)
        end
      }
    end
    builder.to_xml
  end
  
  def connected_user_guids
    user_guids = []
    self.rooms.each do |room|
      user_guids.concat(room.connected_user_guids)
    end
    user_guids.uniq!
    user_guids
  end
  
  def user_list
    user_guids = Array.new
    rooms_by_user_guid = Hash.new
    
    self.rooms.each do |room|
      room_user_guids = room.connected_user_guids
      user_guids.concat(room_user_guids)
      room_user_guids.each do |user_guid|
        rooms_by_user_guid[user_guid] = room
      end
    end
    user_guids.uniq!
    
    users = user_guids.map do |user_guid|
      User.find_by_guid(user_guid)
    end
    users.reject! { |user| user.nil? }
    users.map do |user|
      room = rooms_by_user_guid[user.guid]
      {
        :room_guid => room.guid,
        :room_name => room.name,
        :user_name => user.username,
        :user_guid => user.guid
      }
    end
  end
  
  def population
    user_guids = Array.new
    self.rooms.each do |room|
      room_user_guids = room.connected_user_guids
      user_guids.concat(room_user_guids)
    end
    user_guids.uniq!
    user_guids.length
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
end
