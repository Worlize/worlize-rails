class Admin::BannedIpsController < ApplicationController
  layout 'admin'
  before_filter :require_global_moderator_permission
  
  def index
    scope = BannedIp.order('created_at DESC')
    if params[:q]
      begin
        numeric_ip = ::IPAddr.new(params[:q]).to_i
        scope = scope.where(:ip => numeric_ip)
      rescue
      end
    end
    @banned_ips = scope.all
  end
  
  def show
    @banned_ip = BannedIp.find(params[:id])
  end
  
  def update
    
  end
  
  def new
    @banned_ip = BannedIp.new
    if params[:user]
      @banned_ip.user = User.find_by_guid(params[:user])
      if @banned_ip.user
        @banned_ip.human_ip = @banned_ip.user.current_login_ip unless @banned_ip.user.current_login_ip.nil?
      end
    end
  end
  
  def create
    @banned_ip = BannedIp.new(params[:banned_ip], :as => :admin)
    @banned_ip.created_by = current_user
    @banned_ip.updated_by = current_user
    success = @banned_ip.save
    if success
      redirect_to admin_banned_ips_url
    else
      render :action => :new
    end
  end
  
  def destroy
    @banned_ip = BannedIp.find(params[:id])
    @banned_ip.destroy
    redirect_to admin_banned_ips_url
  end
end
