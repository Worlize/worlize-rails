class Admin::ClientErrorsController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  
  def index
    @errors = ClientErrorLogItem.paginate(:page => params[:page], :per_page => 30).order('created_at DESC')
  end
  
  def show
    @error = ClientErrorLogItem.find(params[:id])
  end
end
