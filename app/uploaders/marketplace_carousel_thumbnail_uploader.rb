# encoding: utf-8

class MarketplaceCarouselThumbnailUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  
  after :store, :delete_old_tmp_file
  
  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog
  
  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['media_cdn_bucket']
  }
  
  define_method 'fog_host', lambda {
      'https://s3.amazonaws.com/' + fog_directory
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
  process :resize_to_fill => [200,100]
  process :convert => 'jpg'#, :quality => 90

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png gif)
  end

  # Override the filename of the uploaded files:
  def filename
    "thumbnail.jpg" if original_filename
  end
  
  # remember the tmp file
  def cache!(new_file)
    super
    @old_tmp_file = new_file
  end
  
  def delete_old_tmp_file(dummy)
    @old_tmp_file.try :delete
  end

end
