class ApplicationController < ActionController::Base
  protect_from_forgery :secret => Worlize::Application.config.secret_token
  layout 'application'
  
  helper :all
  helper_method :current_user_session, :current_user
  
  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
    
    def require_admin
      unless current_user && current_user.admin?
        store_location
        if current_user
          flash[:notice] = "You must have administrator privileges to access this page"
        else
          flash[:notice] = "You must be logged in to access this page"
        end
        redirect_to new_user_session_url
        return false
      end
    end
    
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to account_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.fullpath
    end
    
    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end
  
end
