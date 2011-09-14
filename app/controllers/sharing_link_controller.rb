class SharingLinkController < ApplicationController
  before_filter :require_user, :except => [:show]
  
  def show
    link = SharingLink.active.where(:code => params[:link_code]).first
    if link.nil?
      render_404 and return
    end
    
    room = link.room
    Rails.logger.info("Room id: #{room.id}")
    
    if current_user
      redirect_to enter_room_url(room.guid) and return
    else
      # Render the login page
      store_location
      @sharing_link = link
      @user_session = UserSession.new
      render :layout => 'login'
    end
  end
  
  def create
    room = Room.find_by_guid[:room_guid]
    if room.nil?
      render :json => Yajl::Encoder.encode({
        :success => false,
        :message => 'Specified room guid does not exist'
      })
    end
    
    link = SharingLink.active.where(
      :user_id => current_user.id,
      :room_id => room.id
    ).first
    
    if link.nil?
      link = SharingLink.create(
        :room => room,
        :user => current_user,
        :expires_at => 2.weeks.from_now
      )
    end
    
    if link.persisted?
      render :json => Yajl::Encoder.encode({
        :success => true,
        :url => sharing_link_url(link)
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :message => 'Unable to create requested link'
      })
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

