class Background < ActiveRecord::Base
  has_many :background_instances
  belongs_to :creator, :class_name => 'User'
  before_create :assign_guid

  mount_uploader :image, BackgroundUploader

  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end

end



# class BackgroundImageAsset < ActiveRecord::Base
#   has_attached_file :image,
#                     :styles => { :fullsize => "900x540#", :medium => "275x165#", :thumbnail => "133x80#" },
#                     :storage => :s3,
#                     :s3_credentials => "#{Rails.root}/config/s3.yml",
#                     :path => ":id/:style.:extension",
#                     :bucket => "worlize_backgrounds_dev"
#                     
# end
