class ClientErrorsController < ApplicationController
  before_filter :require_user
  
  def create
    @client_error_log_item = ClientErrorLogItem.new(params)
    @client_error_log_item.user = current_user

    respond_to do |format|
      if @client_error_log_item.save
        format.json do
          render :json => {
            :success => true
          }
        end
      else
        format.json do
          render :json => {
            :success => false
          }
        end
      end
    end
    
    ClientErrorLogItem.delete_all(['created_at < ?', 3.months.ago])
  end
end
