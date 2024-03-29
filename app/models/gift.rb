class Gift < ActiveRecord::Base
  belongs_to :giftable, :polymorphic => true
  belongs_to :sender, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'

  before_create :assign_guid
  after_create :notify_recipient
  
  # validates :sender, :presence => true
  validates :recipient, :presence => true
  validates :giftable, :presence => true
  
  def hash_for_api
    if giftable.respond_to? 'hash_for_gift_api'
      item_detail = giftable.hash_for_gift_api
    elsif giftable.respond_to? 'hash_for_api'
      item_detail = giftable.hash_for_api
    else
      item_detail = nil
    end
    
    {
      :guid => guid,
      :type => giftable_type,
      :note => note,
      :sender => sender.nil? ? nil : sender.public_hash_for_api,
      :item => item_detail
    }
  end
  
  
  private
  def notify_recipient
    if !recipient.nil?
      if recipient.online?
        recipient.send_message({
          :msg => 'gift_received',
          :data => {
            :gift => self.hash_for_api
          }
        })
      else
        unless sender.nil?
          email = EventNotifier.new_gift_email({
            :sender => sender,
            :recipient => recipient,
            :gift => self
          })
          email.deliver
        end
      end
    end
  end
  
  def assign_guid()
    self.guid = Guid.new.to_s
  end
  
end
