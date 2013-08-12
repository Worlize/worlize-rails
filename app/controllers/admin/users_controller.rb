class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin, :except => ['login_as_user','show','index','restrictions']
  before_filter :require_global_moderator_permission, :only => ['show','index','restrictions']
  before_filter :require_admin_without_storing_location, :only => ['login_as_user']
  
  def index
    unless current_user.admin? || current_user.permissions.include?('can_view_admin_user_list')
      flash[:error] = "You do not have permission to view the user list."
      redirect_to admin_index_url and return
    end
    
    # Handle query parameter
    if params[:q]
      # If the user pastes a GUID, then they're looking for a specific user.
      if /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.match(params[:q].downcase)
        @users = User.where(['guid = ?', params[:q]])
        
      # If the user pastes an IP address, they're looking for users who last logged in from that IP.
      elsif /^\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b$/.match(params[:q])
        @users = User.where(:current_login_ip => params[:q])
        
      else
        query = "#{params[:q]}%"
        @users = User.where(['username LIKE ? OR email LIKE ? OR login_name LIKE ?', query, query, query])
      end
    else
      @users = User.scoped
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
    unless current_user.admin? || current_user.permissions.include?('can_view_admin_user_detail')
      flash[:error] = "You do not have permission to view user profiles."
      redirect_to admin_index_url and return
    end
    
    @user ||= User.find(params[:id])
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
  
  def restrictions
    @user ||= User.find(params[:id])
    @restrictions = @user.user_restrictions.order('`user_restrictions`.`created_at` DESC')
  end
  
  def update
    @user = User.find(params[:id])
    if !params[:user]
      format.html { redirect_to(admin_user_url(@user), :notice => 'No attributes provided to update') }
      return
    end
    
    if params[:user][:password].nil? || params[:user][:password].empty?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    @user.skip_username_change_date_validation = true
    
    @user.update_attributes(params[:user], :as => :admin)
    if @user.save
      should_notify_client_that_slots_changed = false
      
      # Record audit log items
      @user.previous_changes.each_pair do |key,changes|
        # Record special information if the admin user changed the number of
        # slots in a user's locker.
        if key =~ /^(.*)_slots$/
          should_notify_client_that_slots_changed = true
          begin
            prev_value = changes[0]
            new_value = changes[1]
            difference = new_value.to_i - prev_value.to_i
          rescue
            difference = 0
          end
          Worlize.audit_logger.info("action=locker_slots_changed_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\" slot_type=#{$1} difference=#{difference}")
          next
        end
        
        # Otherwise just log the relevant changes
        unless ['perishable_token','updated_at'].include?(key)
          Worlize.audit_logger.info("action=user_field_changed_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\" field_name=#{key} old_value=#{changes[0]} new_value=#{changes[1]}")
        end
      end
      
      @user.notify_client_of_slots_change if should_notify_client_that_slots_changed

      respond_to do |format|
        format.html { redirect_to(admin_user_url(@user), :notice => 'User was successfully updated.') }
      end
    else
      show
      render :show
      # format.html { redirect_to(admin_user_url(@user), :error => 'Unable to update user.  Invalid data.') }
    end
  end
  
  def transactions
    @user = User.find(params[:id])
    
    @total_payments = 0
    @user.payments.each do |p|
      @total_payments += p.amount
    end
    
    @coins_balance = 0
    @bucks_balance = 0
    @user.virtual_financial_transactions.each do |t|
      @coins_balance += t.coins_amount unless t.coins_amount.nil?
      @bucks_balance += t.bucks_amount unless t.bucks_amount.nil?
    end
    
  end
  
  def login_as_user
    @user = User.find(params[:id])
    Worlize.audit_logger.info("action=admin_logged_in_as_user user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
    UserSession.find.destroy
    UserSession.create(@user)
    redirect_to dashboard_url
  end
  
  def set_as_global_moderator
    @user = User.find(params[:id])
    @user.set_as_global_moderator
    flash[:notice] = "User #{@user.username} set as global moderator."
    redirect_to admin_user_url(@user)
  end
  
  def unset_as_global_moderator
    @user = User.find(params[:id])
    @user.unset_as_global_moderator
    flash[:notice] = "User #{@user.username} removed as global moderator."
    redirect_to admin_user_url(@user)
  end
  
  def give_currency
    @user = User.find(params[:id])
    if params[:amount].nil? || params[:amount].to_i <= 0
      flash[:error] = "Amount must be a positive integer."
      redirect_to transactions_admin_user_url(@user) and return
    end
    if params[:currency_type] == 'coins'
      transaction = @user.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :comment => "#{params[:comment]} (#{current_user.username})",
        :coins_amount => params[:amount]
      )
    elsif params[:currency_type] == 'bucks'
      transaction = @user.virtual_financial_transactions.create(
        :kind => VirtualFinancialTransaction::KIND_CREDIT_ADJUSTMENT,
        :comment => "#{params[:comment]} (#{current_user.username})",
        :bucks_amount => params[:amount]
      )
    else
      flash[:error] = "Currency type must be either coins or bucks"
      redirect_to transactions_admin_user_url(@user) and return
    end

    if transaction.persisted?
      escaped_comment = params[:comment] ? params[:comment].gsub('"','\"') : ''
      Worlize.audit_logger.info("action=currency_given_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\" currency_type=#{params[:currency_type]} amount=#{params[:amount]} comment=\"#{escaped_comment}\"")
      flash[:notice] = "Successfully credited #{params[:currency_type]} to #{@user.username}."
      @user.recalculate_balances
      @user.notify_client_of_balance_change
    else
      flash[:error] = "There was an error while crediting #{@user.username}'s account: <br>".html_safe +
                      "#{transaction.errors.full_messages.join(', ')}"
    end
    redirect_to transactions_admin_user_url(@user)
  end
  
  def destroy
    begin
      @user = User.find(params[:id])
      if @user.update_attribute(:suspended, true)
        Worlize.audit_logger.info("action=account_suspended_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
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
        Worlize.audit_logger.info("action=account_unsuspended_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
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
    Worlize.audit_logger.info("action=world_set_as_initial_template_world world_guid=#{world.guid} admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
    flash[:notice] = "#{world.name} has been set as the template for the initial world created for new users."
    redirect_to admin_user_url(@user)
  end
  
  def new
    @user = User.new
  end
  
  def create
    User.transaction do
      @user = User.new(params[:user])
      @user.accepted_tos = true
      @user.save
    end
    
    if @user.persisted?
      Worlize.audit_logger.info("action=account_created_by_admin user=#{@user.guid} user_username=\"#{@user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
      @user.create_world
      @user.first_time_login
      flash[:notice] = "Account for #{@user.name} successfully created."
      redirect_to admin_user_url(@user)
    else
      render :action => :new
    end
  end
  
  
  def add_to_public_worlds
    @user = User.find(params[:id])
    @world = @user.worlds.first
    if @world && @world.public_world.nil?
      @world.public_world = PublicWorld.new
      @world.public_world.save
    end
    Worlize.audit_logger.info("action=world_added_to_public_worlds_by_admin world_guid=#{@world.guid} admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
    redirect_to admin_user_url(@user), :notice => "Added #{@world.name} to the list of public worlds."
  end
  
  def remove_from_public_worlds
    @user = User.find(params[:id])
    @world = @user.worlds.first
    if @world && @world.public_world
      @world.public_world.destroy
    end
    Worlize.audit_logger.info("action=world_removed_from_public_worlds_by_admin world_guid=#{@world.guid} admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
    redirect_to admin_user_url(@user), :notice => "Removed #{@world.name} from the list of public worlds."
  end
end
