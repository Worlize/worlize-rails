class Admin::ManagementController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  
  def show
    
  end
  
  def broadcast_message
    unless params[:message].empty?
      Worlize::PubSub.publish('globalBroadcast', {
        :msg => "global_msg",
        :data => params[:message]
      })
      flash[:notice] = "Message sent successfully."
    end
    redirect_to admin_management_path
  end
  
end
