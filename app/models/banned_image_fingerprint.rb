class BannedImageFingerprint < ActiveRecord::Base
  # attr_accessible :title, :body
  
  validates :dct_fingerprint, :uniqueness => { :message => 'has already been banned' }
end
