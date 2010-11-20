class Admin::AuthenticationsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  # DELETE /authentications/1
  # DELETE /authentications/1.xml
  def destroy
    @authentication = Authentication.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to(admin_user_url(@authentication.user)) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

end
