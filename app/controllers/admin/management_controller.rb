class Admin::ManagementController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  
  def show
    
  end
  
  def broadcast_message
    unless params[:message].empty?
      escaped_message = params[:message].gsub('"', '\"')
      Worlize.audit_logger.info("action=global_message_broadcast_by_admin admin=#{current_user.guid} admin_username=\"#{current_user.username}\" message=\"#{escaped_message}\"")
      Worlize::PubSub.publish('globalBroadcast', {
        :msg => "global_msg",
        :data => params[:message]
      })
      flash[:notice] = "Message sent successfully."
    end
    redirect_to admin_management_path
  end
  
end
