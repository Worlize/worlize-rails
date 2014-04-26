class MarketplaceCreator < ActiveRecord::Base
  
  belongs_to :user
  has_many :marketplace_items

  validates :display_name, :presence => true, :uniqueness => true
  validates :first_name,   :presence => true, :if => lambda { !self.user_id.nil? }
  validates :last_name,    :presence => true, :if => lambda { !self.user_id.nil? }
  validates :address1,     :presence => true, :if => lambda { !self.user_id.nil? }
  validates :address2,     :presence => true, :if => lambda { !self.user_id.nil? }
  validates :city,         :presence => true, :if => lambda { !self.user_id.nil? }
  validates :state,        :presence => true, :if => lambda { !self.user_id.nil? }
  validates :phone,        :presence => true, :if => lambda { !self.user_id.nil? }
 
  validates :zipcode,
              presence: true,
              format: {
                with: /^\d{5}(-\d{4})?$/,
                message: 'Must be a valid US Zip Code'
              },
              if: lambda { !self.user_id.nil? }
 
end
