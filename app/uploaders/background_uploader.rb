# encoding: utf-8

class BackgroundUploader < CarrierWave::Uploader::Base

  # Include RMagick or ImageScience support
  include CarrierWave::RMagick
  #     include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader
  #storage :file
  storage :s3

  def s3_cnamed
    ::Rails.env == 'production'
  end

  define_method 's3_bucket', lambda {
      Worlize.config['amazon']['backgrounds_bucket']
  }

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{model.guid}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  #     def default_url
  #       "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  #     end

  process :resize_to_fill => [950, 570]
  
  version :thumb do
    process :resize_to_fill => [133, 80]
  end
  
  version :square_thumb do
    process :resize_to_fill => [80, 80]
  end
  
  version :medium do
    # process :resize_to_fill => [275, 165]
    process :resize_to_fill => [200, 120]
  end

  # Process files as they are uploaded.
  #     process :scale => [200, 300]
  #
  #     def scale(width, height)
  #       # do something
  #     end

  # Create different versions of your uploaded files
  #     version :thumb do
  #       process :scale => [50, 50]
  #     end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #     def extension_white_list
  #       %w(jpg jpeg gif png)
  #     end

  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg" if original_filename
  #     end

end
