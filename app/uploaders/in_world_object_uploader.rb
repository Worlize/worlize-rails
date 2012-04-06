# encoding: utf-8

class InWorldObjectUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  
  after :store, :delete_old_tmp_file

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog
  
  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['in_world_objects_bucket']
  }
  
  define_method 'fog_host', lambda {
      'https://s3.amazonaws.com/' + fog_directory
  }

  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{model.guid}"
  end

  process :resize_to_limit => [950, 570]
  process :set_content_type
  
  version :thumb do
    process :resize_and_pad => [80, 80, "#F0F0F0"]
    process :set_content_type
  end
  
  version :medium do
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
  
  # remember the tmp file
  def cache!(new_file)
    super
    @old_tmp_file = new_file
  end
  
  def delete_old_tmp_file(dummy)
    @old_tmp_file.try :delete
  end

end
