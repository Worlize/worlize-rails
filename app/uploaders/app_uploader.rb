# encoding: utf-8

class AppUploader < CarrierWave::Uploader::Base
  include CarrierWave::MimeTypes

  storage :fog
  
  after :store, :delete_old_tmp_file

  define_method 'fog_directory', lambda {
      Worlize.config['amazon']['swf_api_bucket']
  }
  
  define_method 'fog_host', lambda {
      'https://' + fog_directory + '.s3.amazonaws.com'
  }
  
  def store_dir
    model.guid
  end
  
  process :set_content_type

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(swf)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    'app.swf' if original_filename
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
