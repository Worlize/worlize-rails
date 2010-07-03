class World < ActiveRecord::Base
  before_create :assign_guid

  belongs_to :user
  has_many :rooms
  
  validates :name, :presence => true

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
end
