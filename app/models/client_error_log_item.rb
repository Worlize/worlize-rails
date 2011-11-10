class ClientErrorLogItem < ActiveRecord::Base
  belongs_to :user
  
  attr_accessible :name
  attr_accessible :error_type
  attr_accessible :stack_trace
  attr_accessible :log_text
  attr_accessible :message
  attr_accessible :error_id
end
