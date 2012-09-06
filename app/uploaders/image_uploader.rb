# encoding: utf-8

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes

  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  # storage :s3
  storage :fog

  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['media_cdn_bucket']
  }
  
  define_method 'fog_host', lambda {
      'https://s3.amazonaws.com/' + fog_directory
  }
  
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "images/#{model.class.to_s.underscore}/#{model.id}/#{mounted_as}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    fallback_method = "#{mounted_as}_fallback"
    model.respond_to?(fallback_method) ? model.send(fallback_method) : nil
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end
  
  process :set_content_type

  version :thumb do
    process :resize_to_limit => [600,200]
    process :set_content_type
  end
  
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
