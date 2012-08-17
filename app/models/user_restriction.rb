class UserRestriction < ActiveRecord::Base
  belongs_to :world
  belongs_to :user
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by'
  
  scope :active, lambda {
    where(['expires_at > ?', Time.now])
  }
  
  after_save :update_redis_cache
  after_save :publish_notification
  after_destroy :remove_from_redis_cache
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
      )
    }
  validates :world, :presence => { :if => Proc.new { |ur| !ur.global? } }
  validates :user, :presence => true
  validates :created_by, :presence => true
  validates :updated_by, :presence => true
  validates :expires_at,
    :presence => true,
    :timeliness => {
      :on_or_after => lambda { 50.seconds.from_now },
      :if => Proc.new { |r| r.expires_at_changed? },
      :message => "must be at least 50 seconds in the future.",
      :on => :create
    }
  validate :check_can_lengthen_restriction_time, :on => :update
  validate :check_can_reduce_restriction_time, :on => :update  
  validate :check_has_permission, :on => :create
  
  private
  
  def update_redis_cache
    active_restrictions = UserRestriction.active.where(:user_id => user_id)
    if !global
      active_restrictions = active_restrictions.where(:world_id => world.id)
    end

    expiration = 0
    json = Yajl::Encoder.encode(active_restrictions.map { |restriction|
      expiration = [restriction.expires_at.to_i - Time.now.to_i, expiration].max
      {
        :name => restriction.name,
        :expires => restriction.expires_at.utc
      }
    })
    
    remove_from_redis_cache and return if expiration == 0
    
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
      errors[:base] << "#{user.username} does not have permission to enforce #{name} restrictions."
    end
  end
  
  def check_can_lengthen_restriction_time
    if expires_at_changed? && expires_at > expires_at_was
      
      if global
        permissions = updated_by.permissions
      else
        permissions = updated_by.applied_permissions(world.guid)
      end
      
      unless permissions.include?('can_lengthen_restriction_time')
        errors[:base] << 'Only users with the "can_lengthen_restriction_time" permission can lengthen the restriction time.'
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
      
      unless permissions.include?('can_reduce_restriction_time')
        errors[:base] << 'Only users with the "can_reduce_restriction_time" permission can reduce the restriction time.'
      end
    end
  end
  
end
