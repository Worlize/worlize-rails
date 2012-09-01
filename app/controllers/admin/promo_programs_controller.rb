class Admin::PromoProgramsController < ApplicationController
  layout 'admin'
  before_filter :require_admin

  def index
    @promo_programs = PromoProgram.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @promo_programs }
    end
  end
  
  def new
    @promo_program = PromoProgram.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @promo_program }
    end
  end
  
  def show
    @promo_program = PromoProgram.find(params[:id])
    @image_asset = ImageAsset.new(:imageable => @promo_program)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @promo_program }
    end
  end
    
  def update
    @promo_program = PromoProgram.find(params[:id])
    @image_asset = ImageAsset.new(:imageable => @promo_program)

    respond_to do |format|
      if @promo_program.update_attributes(params[:promo_program])
        format.html { redirect_to(admin_promo_program_url(@promo_program), :notice => 'Promo Program was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "show" }
        format.xml  { render :xml => @promo_program.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def create
    @promo_program = PromoProgram.new(params[:promo_program])

    respond_to do |format|
      if @promo_program.save
        format.html { redirect_to(admin_promo_programs_url, :notice => 'Promo Program was successfully created.') }
        format.xml  { render :xml => @promo_program, :status => :created, :location => [:admin, @promo_program] }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @promo_program.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def upload_image_asset
    @promo_program = PromoProgram.find(params[:id])
    @image_asset = @promo_program.image_assets.new(params[:image_asset])
    if @image_asset.save
      redirect_to admin_promo_program_url(@promo_program)
    else
      render 'show'
    end
  end
  
  def destroy_image_asset
    @image_asset = ImageAsset.find(params[:id])
    @promo_program = @image_asset.imageable
    @image_asset.destroy
    redirect_to admin_promo_program_url(@promo_program)
  end
  
  def destroy
    @promo_program = PromoProgram.find(params[:id])
    @promo_program.destroy

    respond_to do |format|
      format.html { redirect_to(admin_promo_programs_url) }
      format.xml  { head :ok }
    end
  end
end
