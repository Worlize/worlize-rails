# encoding: utf-8

class BackgroundUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  include CarrierWave::MimeTypes
  
  # Choose what kind of storage to use for this uploader
  #storage :file
  storage :fog

  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['backgrounds_bucket']
  }

  define_method 'fog_host', lambda {
      'https://s3.amazonaws.com/' + fog_directory
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

  process :collapse
  process :calculate_image_phash
  process :convert => 'jpg'#, :quality => 90
  process :resize_to_fill => [950, 570]
  process :set_content_type
  process :save_version_dimensions_to_model
  
  version :thumb do
    process :resize_to_fill => [133, 80]
    process :convert => 'jpg'#, :quality => 90
    process :set_content_type
  end
  
  version :square_thumb do
    process :resize_to_fill => [80, 80]
    process :convert => 'jpg'#, :quality => 90
    process :set_content_type
  end
  
  version :medium do
    # process :resize_to_fill => [275, 165]
    process :resize_to_fill => [200, 120]
    process :convert => 'jpg'#, :quality => 90
    process :set_content_type
  end
  
  version :fullsize do
    process :resize_to_fill => [950, 570]
    process :convert => 'jpg'#, :quality => 90
    process :set_content_type
  end
  
  def collapse
    manipulate! do |img|
      img.collapse!
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
    Rails.logger.info("Calculating hash for background #{current_path}")
    # Copy file to temp location
    path_parts = File.split(current_path)
    path_parts[1] = "dcthash-#{path_parts[1]}.tiff"
    tmp_file_path = File.join(path_parts)
    `cp #{current_path} #{tmp_file_path}`
    image = MiniMagick::Image.open(current_path)
    image.collapse!
    image.format('tiff', 0)
    image.write(tmp_file_path)
    image_fingerprint = (model.image_fingerprint ||= ImageFingerprint.new)
    image_fingerprint.dct_fingerprint = Phash.image_hash(tmp_file_path).data
    Rails.logger.info("Fingerprint for #{current_path} is #{image_fingerprint.dct_fingerprint}")
    image.destroy!
    File.unlink(tmp_file_path) if File.exists?(tmp_file_path)
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
  def filename
    "background.jpg" if original_filename
  end

end
