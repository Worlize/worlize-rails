class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :event_theme
  belongs_to :event_room_option
  belongs_to :room
  has_many :comments, :as => :commentable
  
  before_create :assign_guid

  private
  
  def assign_guid
    self.guid = Guid.new.to_s
  end

end
