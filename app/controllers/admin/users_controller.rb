class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  
  def index
    @users = User.paginate(:page => params[:page], :order => 'created_at DESC')
  end
  
  def show
    @user = User.find(params[:id])
    @payments = @user.payments
    @total_payments = 0
    @payments.each do |p|
      @total_payments += p.amount
    end
    
    @virtual_financial_transactions = @user.virtual_financial_transactions
    @coins_balance = 0
    @bucks_balance = 0
    @virtual_financial_transactions.each do |t|
      @coins_balance += t.coins_amount unless t.coins_amount.nil?
      @bucks_balance += t.bucks_amount unless t.bucks_amount.nil?
    end
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
    rescue => detail
      flash[:error] = detail.message
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
