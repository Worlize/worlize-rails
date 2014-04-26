# encoding: utf-8

class ProfileImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes

  # Choose what kind of storage to use for this uploader
  # storage :file
  storage :fog

  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['profile_images_bucket']
  }

  define_method 'fog_host', lambda {
      'https://s3.amazonaws.com/' + fog_directory
  }
  
  # Override the directory where uploaded files will be stored
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "#{model.id}"
  end

  process :set_content_type
  process :resize_to_fill => [851, 315]
  
  version :thumb do
    process :efficient_build_thumb
  end
  
  def efficient_build_thumb
    manipulate! do |img|
      if img.mime_type.match /gif/
        img.collapse!
      end
      img.combine_options do |c|
        c.thumbnail "200x74>"
        c.background '#F0F0F0'
        c.gravity 'Center'
        c.extent '200x74'
      end
      img = yield(img) if block_given?
      img
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded
  #     def default_url
  #       "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  #     end
  
  def default_url
    case version_name
    when ''
      '/cover-default-1.jpg'
    when 'thumb'
      '/thumb_cover-default-1.jpg'
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
