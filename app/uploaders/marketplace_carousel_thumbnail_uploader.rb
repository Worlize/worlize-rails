# encoding: utf-8

class MarketplaceCarouselThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  
  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog
  
  define_method 'fog_directory', lambda {
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
  process :convert => 'jpg', :quality => 90, :resize_to_fill => [200,100]

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png gif)
  end

  # Override the filename of the uploaded files:
  def filename
    "thumbnail.jpg" if original_filename
  end

end
