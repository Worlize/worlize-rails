class Gift < ActiveRecord::Base
  belongs_to :giftable, :polymorphic => true
  belongs_to :sender, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'

  before_create :assign_guid
  
  validates :sender, :presence => true
  validates :recipient, :presence => true
  validates :giftable, :presence => true
  
  def hash_for_api
    if giftable.respond_to? 'hash_for_gift_api'
      item_detail = giftable.hash_for_gift_api
    elsif giftable.resond_to? 'hash_for_api'
      item_detail = giftable.hash_for_api
    else
      item_detail = nil
    end
    
    {
      :guid => guid,
      :type => giftable_type,
      :note => note,
      :sender => sender.public_hash_for_api,
      :item => item_detail
    }
  end
  
  
  private
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
