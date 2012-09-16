class EventRoomOption < ActiveRecord::Base
  acts_as_list :scope => :event_theme_id
  
  attr_accessible :name
  belongs_to :event_theme
  belongs_to :room
end
