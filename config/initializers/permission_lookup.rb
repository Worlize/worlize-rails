module Worlize
  module PermissionLookup
    
    @permission_names = [
      "can_access_moderation_dialog",
      "can_bless_moderators",
      "can_grant_permissions",
      "can_ban",
      "can_pin",
      "can_gag",
      "can_block_avatars",
      "can_block_webcams",
      "can_block_props",
      "can_reduce_restriction_time",
      "can_lengthen_restriction_time",
      "can_edit_rooms",
      "can_create_rooms",
      "can_delete_rooms",
      "can_moderate_globally",
      "can_view_admin_user_detail",
      "can_view_admin_user_list",
      "can_ban_ip"
    ]
    
    @world_owner_permission_names = [
      "can_access_moderation_dialog",
      "can_bless_moderators",
      "can_grant_permissions",
      "can_ban",
      "can_pin",
      "can_gag",
      "can_block_avatars",
      "can_block_webcams",
      "can_block_props",
      "can_reduce_restriction_time",
      "can_lengthen_restriction_time",
      "can_edit_rooms",
      "can_create_rooms",
      "can_delete_rooms"
    ]
    
    @permission_hash = {}
    
    @permission_names.each_index do |index|
      name = @permission_names[index]
      perm_id = index+1
      @permission_hash[perm_id.to_s] = name
      @permission_hash[perm_id] = name
      @permission_hash[name] = perm_id.to_s
    end
    
    def self.permission_map
      return @permission_hash
    end
    
    def self.permission_names
      return @permission_names
    end
    
    def self.world_owner_permission_names
      return @world_owner_permission_names
    end
    
    def self.normalize_to_permission_id(perm)
      if perm.is_a?(Fixnum) && !@permission_hash[perm].nil?
        return perm.to_s
      end
      
      if perm.is_a?(String) && perm.to_i > 0
        return perm
      end
      
      if perm.is_a?(String) && !@permission_hash[perm].nil?
        return @permission_hash[perm]
      end
      
      raise ArgumentError.new("Unknown permission: '#{perm}'")
    end
  end
end
