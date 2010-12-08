class Admin::StatusController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  
end
