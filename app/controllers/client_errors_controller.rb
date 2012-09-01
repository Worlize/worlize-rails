class ClientErrorsController < ApplicationController
  before_filter :require_user
  
  def create
    a = params[:log_text]
    if a && a.length > 60000
      # Slice out the last 60,000 characters from the log to make sure that
      # we don't overflow the 64KiB limit in a MySQL TEXT column while getting
      # the most relevant data - the data at the end of the log.
      params[:log_text] = a[a.length-60000..a.length]
    end
    
    @client_error_log_item = ClientErrorLogItem.new(
      :name => params[:name],
      :error_type => params[:error_type],
      :stack_trace => params[:stack_trace],
      :log_text => params[:log_text],
      :message => params[:message],
      :error_id => params[:error_id],
      :flash_version => params[:flash_version]
    )
    @client_error_log_item.user = current_user

    Worlize.event_logger.info("action=flash_client_error user=#{current_user.guid} user_username=\"#{current_user.username}\"")

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
