class UserRestriction < ActiveRecord::Base
  belongs_to :world
  belongs_to :user
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
  
  scope :active, lambda {
    where(['expires_at > ?', Time.now])
  }
  
  scope :inactive, lambda {
    where(['expires_at <= ?', Time.now])
  }
  
  scope :global, lambda {
    where(['global = ?', true])
  }
  
  after_save :update_redis_cache
  after_save :publish_notification
  after_destroy :update_redis_cache
  after_destroy :publish_notification
  
  validates :name,
    :presence => true,
    :inclusion => {
      :in => %w(
        ban
        pin
        gag
        block_avatars
        block_webcams
        block_props
      ),
      :message => "%{value} is not a valid restriction"
    }
  validates :world, :presence => { :if => Proc.new { |ur| !ur.global? } }
  validates :user, :presence => true
  validates :created_by, :presence => true
  validates :updated_by, :presence => true
  validates :expires_at, :presence => true
  
  validate :check_can_lengthen_restriction_time, :on => :update
  validate :check_can_reduce_restriction_time, :on => :update  
  validate :check_has_permission, :on => :create
  validate :protect_global_moderators, :on => :create
  
  def hash_for_api
    return {
      :id => id,
      :name => name,
      :user => user.nil? ? nil : user.public_hash_for_api,
      :created_by => created_by.nil? ? nil : created_by.public_hash_for_api,
      :updated_by => updated_by.nil? ? nil : updated_by.public_hash_for_api,
      :expires => expires_at.utc,
      # :world => world.nil? ? nil : world.basic_hash_for_api,
      :global => global?
    }
  end
  
  def active?
    self.expires_at > Time.now
  end
  
  private
  
  def update_redis_cache
    active_restrictions = UserRestriction.active.where(:user_id => user_id)
    if global
      active_restrictions = active_restrictions.where(:global => true)
    else
      active_restrictions = active_restrictions.where(:world_id => world.id)
    end

    remove_from_redis_cache and return if active_restrictions.length == 0

    expiration = 0
    json = Yajl::Encoder.encode(active_restrictions.map { |restriction|
      expiration = [restriction.expires_at.to_i - Time.now.to_i, expiration].max
      {
        :name => restriction.name,
        :expires => restriction.expires_at.utc
      }
    })
    
    redis = Worlize::RedisConnectionPool.get_client(:restrictions)
    if global
      redis.setex("g:#{self.user.guid}", expiration, json)
    else
      redis.setex("w:#{self.world.guid}:#{self.user.guid}", expiration, json)
    end
  end
  
  def remove_from_redis_cache
    redis = Worlize::RedisConnectionPool.get_client(:restrictions)
    if global
      redis.del("g:#{self.user.guid}")
    else
      redis.del("w:#{self.world.guid}:#{self.user.guid}")
    end
  end
  
  def publish_notification
    return unless user.online?
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
  
  def check_has_permission
    if global
      permissions = updated_by.permissions
    else
      permissions = updated_by.applied_permissions(world.guid)
    end
    
    unless permissions.include?("can_#{name}")
      errors[:base] << "#{updated_by.username} does not have permission to enforce #{name} restrictions."
    end
  end
  
  def protect_global_moderators
    if user.permissions.include?('can_moderate_globally') &&
       !created_by.permissions.include?('can_moderate_globally')
      errors[:base] << 'You cannot place restrictions on a global moderator.'
    end
  end
  
  def check_can_lengthen_restriction_time
    if expires_at_changed? && expires_at > expires_at_was
      
      if global
        permissions = updated_by.permissions
      else
        permissions = updated_by.applied_permissions(world.guid)
      end
      
      # Allow moderators to change the time of their own enforcements
      return if updated_by.id == created_by.id

      unless permissions.include?('can_lengthen_restriction_time')
        errors[:base] << 'Permission to lengthen the restriction time denied.'
      end
    end
  end
  
  def check_can_reduce_restriction_time
    if expires_at_changed? && expires_at < expires_at_was
      if global
        permissions = updated_by.permissions
      else
        permissions = updated_by.applied_permissions(world.guid)
      end
      
      # Allow moderators to change the time of their own enforcements
      return if updated_by.id == created_by.id
      
      unless permissions.include?('can_reduce_restriction_time')
        errors[:base] << 'Permission to reduce the restriction time or lift the restriction denied.'
      end
    end
  end
  
end
