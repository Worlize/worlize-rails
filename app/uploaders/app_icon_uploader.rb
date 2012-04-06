# encoding: utf-8

class AppIconUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  
  after :store, :delete_old_tmp_file

  # Include RMagick or ImageScience support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  # include CarrierWave::ImageScience

  # Choose what kind of storage to use for this uploader:
  # storage :s3
  storage :fog

  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['swf_api_bucket']
  }
  
  define_method 'fog_host', lambda {
      'https://' + fog_directory + '.s3.amazonaws.com'
  }

  def store_dir
    model.guid
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    "/images/icons/app_icon/" + [version_name, "default.png"].compact.join('_')
  end

  process :resize_to_limit => [128, 128]
  process :set_content_type

  version :small do
    process :resize_and_pad => [64, 64]
    process :set_content_type
  end

  version :medium do
    process :resize_and_pad => [80, 80]
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
  
  # remember the tmp file
  def cache!(new_file)
    super
    @old_tmp_file = new_file
  end
  
  def delete_old_tmp_file(dummy)
    @old_tmp_file.try :delete
  end

end
