class Comment < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :content
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
end
