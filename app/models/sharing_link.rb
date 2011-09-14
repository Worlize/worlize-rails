class SharingLink < ActiveRecord::Base
  belongs_to :room
  belongs_to :user
  
  before_create :generate_code
  
  scope :active, lambda {
    where("expires_at < ?", Time.now)
  }
  
  private
  
  def generate_code
    self.code = Guid.new.to_b62
  end
  
end
