class PermalinksController < ApplicationController
  def show
    p = Permalink.find_by_link!(params[:permalink])
    if p.linkable_type != 'World'
      render_404 and return
    end
    
    world = p.linkable
    redirect_to enter_room_url(world.rooms.first.guid)
  end

  def check_availability
    p = Permalink.new(
      :link => params[:permalink],
      :linkable => World.first
    )
    
    respond_to do |format|
      format.json do
        render :json => {
          :success => p.valid?,
          :message => p.errors.map { |k,v| "- #{k.to_s.humanize} #{v}" }.join(".\n")
        }
      end
    end
  end
  
  private
  
  def render_404(exception = nil)
    if exception
      logger.info "Rendering 404 with exception: #{exception.message}"
    end

    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404.html", :status => :not_found, :layout => nil }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end
end
