class EventThemes < ActiveRecord::Base
  belongs_to :event_category
  has_many :event_room_options
end
