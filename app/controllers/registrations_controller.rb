class RegistrationsController < ApplicationController
  # GET /registrations
  # GET /registrations.xml
  before_filter :require_user, :except => [:create, :new]

  # GET /registrations/new
  # GET /registrations/new.xml
  def new
    @registration = Registration.new

    # Pre-fill as much information as we can from an omniauth login
    if session[:omniauth] && session[:omniauth]['user_info']
      if session[:omniauth]['provider'] == 'facebook'
        @registration.first_name = session[:omniauth]['user_info']['first_name']
        @registration.last_name = session[:omniauth]['user_info']['last_name']
      elsif session[:omniauth]['provider'] == 'twitter'
        name_parts = session[:omniauth]['user_info']['name'].split(' ')
        @registration.first_name = name_parts[0]
        if name_parts.length > 1
          @registration.last_name = name_parts[name_parts.length-1]
        end
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @registration }
    end
  end

  # POST /registrations
  # POST /registrations.xml
  def create
    @registration = Registration.new(params[:registration])
    
    @beta_code = BetaCode.find_by_code(params[:registration][:beta_code])
    if (@registration.valid? && !@beta_code.nil? && !@beta_code.consumed?)
      @invitation = BetaInvitation.create(
        :name => @registration.name,
        :first_name => @registration.first_name,
        :last_name => @registration.last_name,
        :email => @registration.email,
        :beta_code => @beta_code
      )
      redirect_to invite_url(@invitation.invite_code) and return
    end
    
    respond_to do |format|
      if @registration.save
        Notifier.beta_full_email(@registration).deliver
        JessicaNotifier.beta_full_email(@registration).deliver
        format.html { render :action => 'new' }
      else
        format.html { render :action => "new" }
      end
    end
  end

end
