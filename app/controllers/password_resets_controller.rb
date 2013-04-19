class PasswordResetsController < ApplicationController
  layout 'bootstrap'
  
  before_filter :load_user_using_perishable_token, :only => [:show, :update]
  
  def create
    if params.include?(:login_name)
      send_password_reset_by_login_name(params[:login_name])
    elsif params.include?(:email)
      send_password_reset_by_email(params[:email])
    end
  end
  
  def show
  end
  
  def update
    @user.skip_login_name_validation = true
    
    @success = @user.update_attributes({
      :password => params[:user][:password],
      :password_confirmation => params[:user][:password_confirmation]
    })
    
    if !@success
      render :action => 'show' and return
    end
  end
  
  private
  
  def send_password_reset_by_login_name(login_name)
    @user = User.find_by_login_name(login_name)
    return if @user.nil?
    
    @user.reset_perishable_token!
    
    Notifier.password_reset_email(@user.email, [@user]).deliver
  end
  
  def send_password_reset_by_email(email)
    @users = User.where(:email => email, :suspended => false)
    return if @users.empty?
    
    @users.each do |user|
      user.reset_perishable_token!
    end
    
    Notifier.password_reset_email(@users.first.email, @users).deliver
  end

  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user  
      flash[:error] = "We're sorry, but we could not locate your account. " +  
                       "If you are having issues, try copying and pasting the URL " +  
                       "from your email into your browser or restarting the " +  
                       "reset password process."
      redirect_to login_url
      return false
    end
  end
end
