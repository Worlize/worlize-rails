class Admin::AuthenticationsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  # DELETE /authentications/1
  # DELETE /authentications/1.xml
  def destroy
    @authentication = Authentication.find(params[:id])
    Worlize.audit_logger.info("action=external_authentication_unlinked_by_admin auth_provider=#{@authentication.provider} auth_uid=#{@authentication.uid} user=#{@authentication.user.guid} user_username=\"#{@authentication.user.username}\" admin=#{current_user.guid} admin_username=\"#{current_user.username}\"")
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to(admin_user_url(@authentication.user)) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

end
