class Admin::Marketplace::ThemesController < ApplicationController
  layout 'admin'
  before_filter :find_theme, :only => [:show, :edit, :update, :destroy]

  # GET /themes
  # GET /themes.xml
  def index
    @themes = MarketplaceTheme.all

    respond_to do |wants|
      wants.html # index.html.erb
      wants.xml  { render :xml => @themes }
    end
  end

  # GET /themes/1
  # GET /themes/1.xml
  def show
    respond_to do |wants|
      wants.html # show.html.erb
      wants.xml  { render :xml => @theme }
    end
  end

  # GET /themes/new
  # GET /themes/new.xml
  def new
    @theme = MarketplaceTheme.new

    respond_to do |wants|
      wants.html # new.html.erb
      wants.xml  { render :xml => @theme }
    end
  end

  # GET /themes/1/edit
  def edit
  end

  # POST /themes
  # POST /themes.xml
  def create
    @theme = MarketplaceTheme.new(params[:marketplace_theme])

    respond_to do |wants|
      if @theme.save
        flash[:notice] = 'Theme was successfully created.' 
        wants.html { redirect_to(admin_marketplace_themes_path) }
        wants.xml  { render :xml => @theme, :status => :created, :location => [:admin, @theme] }
      else
        wants.html { render :action => "new" }
        wants.xml  { render :xml => @theme.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /themes/1
  # PUT /themes/1.xml
  def update
    respond_to do |wants|
      if @theme.update_attributes(params[:marketplace_theme])
        flash[:notice] = 'Theme was successfully updated.'
        wants.html { redirect_to(admin_marketplace_themes_path) }
        wants.xml  { head :ok }
      else
        wants.html { render :action => "edit" }
        wants.xml  { render :xml => @theme.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /themes/1
  # DELETE /themes/1.xml
  def destroy
    @theme.destroy

    respond_to do |wants|
      wants.html { redirect_to(admin_marketplace_themes_url) }
      wants.xml  { head :ok }
    end
  end

  private
    def find_theme
      @theme = MarketplaceTheme.find(params[:id])
    end

end
