class RegistrationsController < ApplicationController
  # GET /registrations
  # GET /registrations.xml
  before_filter :require_user, :except => [:create, :new]

  # GET /registrations/new
  # GET /registrations/new.xml
  def new
    @registration = Registration.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @registration }
    end
  end

  # POST /registrations
  # POST /registrations.xml
  def create
    @registration = Registration.new(params[:registration])

    respond_to do |format|
      if @registration.save
        if !@registration.developer
          Notifier.beta_full_email(@registration).deliver
        end
        format.html { redirect_to(@registration, :notice => 'Registration was successfully created.') }
        format.js { render :json => { :success => true } }
        format.xml  { render :xml => @registration, :status => :created, :location => @registration }
      else
        format.html { render :action => "new" }
        format.js { render :json => { :success => false, :errors => @registration.errors } }
        format.xml  { render :xml => @registration.errors, :status => :unprocessable_entity }
      end
    end
  end

end
