class MarketplaceLicense < ActiveRecord::Base
  has_many :marketplace_items, :dependent => :nullify
end
