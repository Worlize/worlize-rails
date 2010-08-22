class AvatarsController < ApplicationController

  def new
    @avatar = Avatar.new
  end
  
  def show
    
  end
  
  def create
    file_in = params[:filedata]
    File.open("/Users/turtle/Desktop/uploaded-" + file_in.original_filename, 'w') do |file|
      file.write(file_in.read)
    end
    render :json => Yajl::Encoder.encode({
      :success => true
    })
  end

end
