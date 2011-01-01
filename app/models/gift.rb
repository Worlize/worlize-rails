class Gift < ActiveRecord::Base
  belongs_to :giftable, :polymorphic => true
  belongs_to :sender, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'
  
  validates :sender, :presence => true
  validates :recipient, :presence => true
  validates :giftable, :presence => true
  
  def hash_for_api
    {
      :type => giftable_type,
      :note => note,
      :gift => giftable.hash_for_api
    }
  end
end
