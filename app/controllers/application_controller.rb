class ApplicationController < ActionController::Base
  protect_from_forgery :secret => Worlize::Application.config.secret_token
  layout 'application'
  
  helper :all
  helper_method :current_user_session, :current_user
  helper_method :new_user_session_object
  
  before_filter :set_vary_header
  
  def require_any_permission(*args)
    return true if args.empty?
    args = args[0] if args[0].is_a?(Array)
    
    if current_user
      return true if current_user.admin?
      perms = current_user.permissions
      args.map(&:to_s).each do |permission|
        return true if perms.include?(permission)
      end
    end

    store_location
    if current_user
      flash[:notice] = "You do not have permission to access that page"
    else
      flash[:notice] = "You must be logged in to access that page"
    end
    redirect_to new_user_session_url
    return false
  end
  
  def require_all_permissions(*args)
    return true if args.empty?
    args = args[0] if args[0].is_a?(Array)

    if current_user
      return true if current_user.admin?
      perms = current_user.permissions
      return true if perms.to_set.superset?(args.map(&:to_s).to_set)
    end

    store_location
    if current_user
      flash[:notice] = "You do not have permission to access that page"
    else
      flash[:notice] = "You must be logged in to access that page"
    end
    redirect_to new_user_session_url
    return false
  end

  private
    def set_vary_header
      response.headers['Vary'] = 'Accept'
    end
  
    def new_user_session_object
      UserSession.new
    end
  
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def reset_current_user
      remove_instance_variable(:@current_user)
      remove_instance_variable(:@current_user_session)
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
        
    def require_admin
      unless current_user && current_user.admin?
        store_location
        if current_user
          flash[:notice] = "You must have administrator privileges to access that page"
        else
          flash[:notice] = "You must be logged in to access that page"
        end
        redirect_to new_user_session_url
        return false
      end
    end
    
    def require_admin_without_storing_location
      unless current_user && current_user.admin?
        if current_user
          flash[:notice] = "You must have administrator privileges to access that page"
        else
          flash[:notice] = "You must be logged in to access that page"
        end
        redirect_to new_user_session_url
        return false
      end
    end
    
    def require_global_moderator_permission
      require_all_permissions([:can_moderate_globally, :can_access_moderation_dialog])
    end
        
    def require_user
      unless current_user
        respond_to do |format|
          format.html do
            store_location
            redirect_to new_user_session_url
          end
          format.json do
            render :json => {
              :success => false,
              :message => "An active user session is required to access this resource."
            }
          end
        end
        return false          
      end
    end
    
    def require_user_without_storing_location
      unless current_user
        respond_to do |format|
          format.html do
            redirect_to new_user_session_url
          end
          format.json do
            render :json => {
              :success => false,
              :message => "An active user session is required to access this resource."
            }
          end
        end
        return false
      end
    end
    
    def check_user_migration_required
      return false unless require_login_name_confirmed
      return false unless require_birthday_set
    end
    
    def check_email_verification
      if current_user.state?(:email_unverified)
        store_location
        redirect_to email_unverified_path
        return false
      end
    end
    
    def require_login_name_confirmed
      if current_user.state?(:login_name_unconfirmed) || current_user.state?(:username_invalid)
        store_location
        redirect_to confirm_login_name_path
        return false
      end
      return true
    end

    def require_birthday_set
      if current_user && (current_user.birthday.nil? || current_user.birthday > 13.years.ago.to_date)
        respond_to do |format|
          format.html do
            store_location
            redirect_to birthday_required_path
          end
          format.json do
            render :json => {
              :success => false,
              :message => "You must add your birthday to your profile to perform this action."
            }
          end
        end
        return false
      end
      return true
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access that page"
        redirect_to root_url
        return false
      end
    end
    
    def store_location_if_not_logged_in
      store_location unless current_user
    end
    
    def store_location
      session[:return_to] = request.fullpath
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
    
    def get_redirect_back_or_default_url(default)
      if Rails.env == 'development'
        Rails.logger.debug "session[:return_to] = #{session[:return_to]}"
      end
      url = session[:return_to] || default
      session[:return_to] = nil
      return url
    end
    
    def get_facebook_user_info
      oauth = Koala::Facebook::OAuth.new(
        Worlize.config['facebook']['app_id'],
        Worlize.config['facebook']['app_secret']
      )
      oauth.get_user_info_from_cookies(cookies)
    end
    
    def get_facebook_access_token
      get_facebook_user_info ? get_facebook_user_info['access_token'] : nil
    end
  
end
