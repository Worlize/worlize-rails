class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin, :except => ['login_as_user']
  before_filter :require_admin_without_storing_location, :only => ['login_as_user']
  
  def index
    # Handle query parameter
    if params[:q]
      # If the user pastes a GUID, then they're looking for a specific user.
      if /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.match(params[:q].downcase)
        @users = User.where(['guid = ?', params[:q]])
      else
        query = "#{params[:q]}%"
        @users = User.where(['username LIKE ? OR email LIKE ?', query, query])
      end
    else
      @users = User.where('1=1') # start with a base no-op query
    end
    
    # Apply pagination
    @users = @users.paginate(:page => params[:page], :per_page => 30)
    
    # Set up the correct sorting
    default_sort_direction = {
      'created_at' => 'desc',
      'username' => 'asc'
    }
    
    params[:sort] = 'created_at' unless params[:sort]
    unless params[:sort_direction]
      params[:sort_direction] = default_sort_direction[params[:sort].downcase]
    end
    
    @opposite_sort_direction = params[:sort_direction] == 'desc' ? 'asc' : 'desc'
    
    if params[:sort] == 'username'
      @users = @users.order('username ' + (params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'))
    elsif params[:sort] == 'created_at'
      @users = @users.order('created_at ' + (params[:sort_direction] == 'desc' ? 'DESC' : 'ASC'))
    end
  end
  
  def show
    @user = User.find(params[:id])
    @world = @user.worlds.first
    @rooms = @world.rooms
    @friends = @user.friends
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
    @user = User.find(params[:id])
    @user.accessible = :all
    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(admin_user_url(@user), :notice => 'User was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def login_as_user
    UserSession.find.destroy
    @user = User.find(params[:id])
    UserSession.create(@user)
    redirect_to dashboard_url
  end
  
  def give_currency
    @user = User.find(params[:id])
    if params[:amount].nil? || params[:amount].to_i <= 0
      flash[:error] = "Amount must be a positive integer."
      redirect_to admin_user_url(@user) and return
    end
    if params[:currency_type] == 'coins'
      transaction = @user.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :comment => params[:comment],
        :coins_amount => params[:amount]
      )
    elsif params[:currency_type] == 'bucks'
      transaction = @user.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :comment => params[:comment],
        :bucks_amount => params[:amount]
      )
    else
      flash[:error] = "Currency type must be either coins or bucks"
      redirect_to admin_user_url(@user) and return
    end

    if transaction.persisted?
      flash[:notice] = "Successfully credited #{params[:currency_type]} to #{@user.username}."
      @user.recalculate_balances
      @user.notify_client_of_balance_change
    else
      flash[:error] = "There was an error while crediting #{@user.username}'s account: <br>".html_safe +
                      "#{transaction.errors.full_messages.join(', ')}"
    end
    redirect_to admin_user_url(@user)
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
    redirect_to admin_user_url(@user)
  end
  
  def reactivate
    begin
      @user = User.find(params[:id])
      if @user.update_attribute(:suspended, false)
        flash[:notice] = "#{@user.username} successfully re-activated."
      else
        flash[:error] = "Unable to re-activate #{@user.username}."
      end
    rescue => detail
      flash[:error] = detail.message
    end
    redirect_to admin_user_url(@user)
  end
  
  def set_world_as_initial_template_world
    @user = User.find(params[:id])
    world = @user.worlds.first
    World.initial_template_world_guid = world.guid
    flash[:notice] = "#{world.name} has been set as the template for the initial world created for new users."
    redirect_to admin_user_url(@user)
  end
  
  def new
    @user = User.new
  end
  
  def create
    User.transaction do
      @user = User.new(params[:user])
      @user.password = params[:user][:password]
      @user.accepted_tos = true
      @user.save
    end
    
    if @user.persisted?
      @user.create_world
      @user.first_time_login
      flash[:notice] = "Account for #{@user.name} successfully created."
      redirect_to admin_user_url(@user)
    else
      render :action => :new
    end
  end
end
