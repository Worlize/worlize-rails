# encoding: utf-8

class InWorldObjectUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :s3
  
  def s3_cnamed
    ::Rails.env == 'production'
  end
  
  define_method 's3_bucket', lambda {
      Worlize.config['amazon']['in_world_objects_bucket']
  }

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{model.guid}"
  end

  process :resize_to_limit => [950, 570], :if => :image?
  process :set_content_type
  
  version :thumb, :if => :image? do
    process :resize_and_pad => [80, 80, "#F0F0F0"]
    process :set_content_type
  end
  
  version :medium, :if => :image? do
    process :resize_to_limit => [200,200]
    process :set_content_type
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
  def extension_white_list
    %w(jpg jpeg gif png swf)
  end

  # Override the filename of the uploaded files:
  # def filename
  #   "something.jpg" if original_filename
  # end

  protected
  
  def image?(new_file)
    return model.is_thumbnable unless model.is_thumbnable.nil?
    model.is_thumbnable = new_file.content_type.include?('image')
  end

end
