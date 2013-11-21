# encoding: utf-8

class InWorldObjectUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  
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

  process :calculate_image_phash
  process :resize_to_limit => [950, 570]
  process :set_content_type
  process :save_version_dimensions_to_model
  
  version :thumb do
    process :efficient_build_thumb
  end
  
  version :medium do
    process :resize_to_limit => [200,200]
  end
  
  def efficient_build_thumb
    manipulate! do |img|
      if img.mime_type.match /gif/
        img.collapse!
      end
      img.combine_options do |c|
        c.thumbnail "80x80>"
        c.background '#F0F0F0'
        c.gravity 'Center'
        c.extent '80x80'
      end
      img = yield(img) if block_given?
      img
    end
  end

  def save_version_dimensions_to_model
    result = `identify -format "%wx%h" "#{file.path}"[0]`
    width, height = result.split(/x/)
    model.width = width
    model.height = height
  rescue
    Rails.logger.warn("Unable to get version image dimensions for avatar " + model.guid)
  end
  
  def calculate_image_phash
    Rails.logger.info("Calculating has for object #{current_path}")
    # Copy file to temp location
    path_parts = File.split(current_path)
    path_parts[1] = "dcthash-#{path_parts[1]}"
    tmp_file_path = File.join(path_parts)
    `cp #{current_path} #{tmp_file_path}`
    image = MiniMagick::Image.open(current_path)
    image.collapse!
    image.write(tmp_file_path)
    image_fingerprint = (model.image_fingerprint ||= ImageFingerprint.new)
    image_fingerprint.dct_fingerprint = Phash.image_hash(tmp_file_path).data
    image.destroy!
    File.unlink(tmp_file_path) if File.exists?(tmp_file_path)
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
  
end
