class Admin::Marketplace::LicensesController < ApplicationController
  layout 'admin'
  before_filter(:only => [:index, :show]) { |c| c.require_all_permissions(:can_administrate_marketplace) }
  before_filter :require_admin, :except => [:index, :show]
  
  # GET /marketplace_licenses
  # GET /marketplace_licenses.xml
  def index
    @marketplace_licenses = MarketplaceLicense.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @marketplace_licenses }
    end
  end

  # GET /marketplace_licenses/1
  # GET /marketplace_licenses/1.xml
  def show
    @marketplace_license = MarketplaceLicense.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @marketplace_license }
    end
  end

  # GET /marketplace_licenses/new
  # GET /marketplace_licenses/new.xml
  def new
    @marketplace_license = MarketplaceLicense.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @marketplace_license }
    end
  end

  # GET /marketplace_licenses/1/edit
  def edit
    @marketplace_license = MarketplaceLicense.find(params[:id])
  end

  # POST /marketplace_licenses
  # POST /marketplace_licenses.xml
  def create
    @marketplace_license = MarketplaceLicense.new(params[:marketplace_license])

    respond_to do |format|
      if @marketplace_license.save
        format.html { redirect_to(admin_marketplace_licenses_url, :notice => 'Marketplace license was successfully created.') }
        format.xml  { render :xml => @marketplace_license, :status => :created, :location => [:admin, @marketplace_license] }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @marketplace_license.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /marketplace_licenses/1
  # PUT /marketplace_licenses/1.xml
  def update
    @marketplace_license = MarketplaceLicense.find(params[:id])

    respond_to do |format|
      if @marketplace_license.update_attributes(params[:marketplace_license])
        format.html { redirect_to(admin_marketplace_licenses_url, :notice => 'Marketplace license was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @marketplace_license.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /marketplace_licenses/1
  # DELETE /marketplace_licenses/1.xml
  def destroy
    @marketplace_license = MarketplaceLicense.find(params[:id])
    @marketplace_license.destroy

    respond_to do |format|
      format.html { redirect_to(admin_marketplace_licenses_url) }
      format.xml  { head :ok }
    end
  end
end
