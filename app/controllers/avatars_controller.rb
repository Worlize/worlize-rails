class AvatarsController < ApplicationController

  def new
    @avatar = Avatar.new
  end
  
  def show
    
  end
  
  def create
    file_in = params[:avatar][:test_upload]
    File.open("/Users/turtle/Desktop/" + file_in.original_filename, 'w') do |file|
      file.write(file_in.read)
    end
    redirect_to new_avatar_url
  end

end
