class ImageAsset < ActiveRecord::Base
  belongs_to :imageable, :polymorphic => true
  mount_uploader :image, ImageAssetUploader
end
