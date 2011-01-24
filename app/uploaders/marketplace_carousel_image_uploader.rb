# encoding: utf-8

class MarketplaceCarouselImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :s3

  def s3_cnamed
    ::Rails.env == 'production'
  end
  
  define_method 's3_bucket', lambda {
      Worlize.config['amazon']['media_cdn_bucket']
  }

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #     "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  #   end
  def store_dir
    "marketplace/carousel/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end


  # Process files as they are uploaded:
  process :convert => 'jpg', :resize_to_limit => [725,200]

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png gif)
  end

  # Override the filename of the uploaded files:
  def filename
    "banner.jpg" if original_filename
  end

end