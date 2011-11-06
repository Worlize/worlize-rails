class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin
  
  def index
    if params[:q]
      @query_param = params[:q]
      query = "#{params[:q]}%"
      relation = User.where(['username LIKE ? OR email LIKE ?', query, query])
    else
      relation = User.active
    end
    @users = relation.paginate(:page => params[:page], :per_page => 50).order('created_at DESC')
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
      if @user.update_attribute(:suspended, true)
        flash[:notice] = "#{@user.username} suspended successfully."
      else
        flash[:error] = "Unable to suspend #{@user.username}."
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
