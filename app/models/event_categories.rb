class EventCategories < ActiveRecord::Base
  has_many :events
  has_many :event_themes
end
