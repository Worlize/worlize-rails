class EventRoomOption < ActiveRecord::Base
  attr_accessible :name
  belongs_to :event_theme
  belongs_to :room
end
