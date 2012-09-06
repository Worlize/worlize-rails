class EventCategory < ActiveRecord::Base
  attr_accessible :name
  has_one :thumbnail, :as => :imageable
  has_many :event_themes
end
