class World < ActiveRecord::Base
  before_create :assign_guid

  belongs_to :user
  has_many :rooms, :dependent => :destroy
  
  validates :name, :presence => true

  def hash_for_api(current_user)
    {
      :guid => self.guid,
      :name => self.name,
      :owner => self.user.public_hash_for_api,
      :can_create_new_room => current_user == self.user,
      :rooms => self.rooms.map do |room|
        {
          :name => room.name,
          :guid => room.guid,
          :user_count => (rand * 15).round
        }
      end
    }
  end

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
end
