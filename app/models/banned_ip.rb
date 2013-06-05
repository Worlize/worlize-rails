class BannedIp < ActiveRecord::Base
  belongs_to :user
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'

  after_save :update_redis_cache
  after_save :publish_notification
  after_destroy :update_redis_cache
  after_destroy :publish_notification
  
  validates :ip, :presence => true, :uniqueness => { :message => 'has already been banned' }
  validates :created_by, :presence => true
  validates :updated_by, :presence => true
  validate :check_has_permission, :on => :create
  
  attr_accessible :user_id, :ip, :human_ip, :created_by, :updated_by, :reason, :as => :admin
  
  def hash_for_api
    return {
      :id => id,
      :ip => human_ip,
      :user => user.nil? ? nil : user.public_hash_for_api,
      :created_at => created_at,
      :created_by => created_by.nil? ? nil : created_by.public_hash_for_api,
      :updated_by => updated_by.nil? ? nil : updated_by.public_hash_for_api,
      :reason => reason
    }
  end
  
  def human_ip
    return '' if self.ip.blank? || self.ip == 0
    ::IPAddr.new(self.ip, Socket::AF_INET).to_s
  end
  
  def human_ip=(new_value)
    begin
      self.ip = ::IPAddr.new(new_value).to_i
    rescue
      self.ip = nil
    end
  end

  private
  
  def update_redis_cache
    redis = Worlize::RedisConnectionPool.get_client(:restrictions)
    redis.multi do
      redis.del('banned_ips')
      banned_ips = BannedIp.select([:id, :ip]).all.map(&:ip)
      redis.sadd('banned_ips', banned_ips) unless banned_ips.empty?
    end
  end
  
  def publish_notification
    users = User.where(:current_login_ip => human_ip)
    users.each do |user|
      next unless user.online?
      Worlize::InteractServerManager.instance.broadcast_to_room(
        user.interactivity_session.room_guid,
        {
          :msg => 'user_restrictions_changed',
          :data => {
            :user => user.guid
          }
        }
      )
    end
  end
  
  def check_has_permission
    permissions = updated_by.permissions
    unless permissions.include?("can_ban_ip")
      errors[:base] << "#{updated_by.username} does not have permission to ban IP addresses."
    end
  end

end
