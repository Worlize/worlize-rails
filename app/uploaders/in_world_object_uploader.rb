# encoding: utf-8

class InWorldObjectUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  # storage :file
  if ::Rails.env == 'production'
    storage :s3
  else
    storage :file
  end
  
  def s3_cnamed
    ::Rails.env == 'production'
  end
  
  define_method 's3_bucket', lambda {
      Worlize.config['amazon']['in_world_objects_bucket']
  }

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if ::Rails.env == 'development'
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    else
      "#{model.guid}"
    end
  end
  
  process :resize_to_limit => [950, 570]
  
  version :thumb do
    process :resize_and_pad => [80, 80, "#F0F0F0"]    
  end
  
  version :medium do
    process :resize_to_limit => [200,200]
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

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

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_white_list
  #   %w(jpg jpeg gif png)
  # end

  # Override the filename of the uploaded files:
  # def filename
  #   "something.jpg" if original_filename
  # end

end
