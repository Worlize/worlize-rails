class EmbedController < ApplicationController
  def render_badge
    begin
      @world = World.find_by_guid(params[:world])
      @entrance_guid = @world.rooms.first.guid
      @population = @world.population
    
      if params[:size] == '128x128'
        render '128x128', :layout => false
      elsif params[:size] == '140x26'
        render '140x26', :layout => false
      else
        raise "Unknown size: #{params[:size]}"
      end
    rescue
      render :text => "Error rendering Worlize embed widget." and return
    end
  end
end
