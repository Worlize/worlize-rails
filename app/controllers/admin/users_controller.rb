class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  
  def index
    @users = User.paginate(:page => params[:page], :order => 'created_at DESC')
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  def update
    
  end
  
  def destroy
    begin
      @user = User.find(params[:id])
      if @user.destroy
        flash[:notice] = "#{@user.username} deleted successfully."
      else
        flash[:error] = "Unable to delete #{@user.username}."
      end
    rescue
      flash[:error] = "Cannot find user with id #{params[:id]}"
    end
    redirect_to admin_users_url
  end
  
  def create
    begin
      User.transaction do
        @user = User.new(params[:user])
        @user.save!
        world = World.new(:user => @user, :name => "#{@user.name}'s Worlz")
        world.save!
        background = Background.first
        bi = BackgroundInstance.create!(:user => @user, :background => background)
        3.times do |i|
          room = world.rooms.create!(:name => "Example room #{i+1}", :background_instance => bi, :world => world)
        end
      end
    rescue
      render :template => 'admin/beta_registrations/build_account'
      return
    end
    flash[:notice] = "Account for #{@user.name} successfully created."
    redirect_to admin_beta_registrations_url
  end
end
