class ImageFingerprint < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :fingerprintable, :polymorphic => true
end
