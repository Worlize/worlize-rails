module Worlize
  class InteractServerManager
    include Singleton
    
    def initialize
      
    end
    
    def active_servers
      r = Worlize::RedisConnectionPool.get_client('presence')
      server_info = r.hgetall('interactServer').map do |server_id, json|
        begin
          data = Yajl::Parser.parse(json)
          data['last_checkin'] = DateTime.parse(data['last_checkin'])
        rescue
          data = nil
        end
        data
      end
      server_info.select do |data|
        !data.nil? && data['last_checkin'] > 11.seconds.ago
      end
    end
    
    def server_for_room(room_guid)
      r = Worlize::RedisConnectionPool.get_client('presence')
      assigned_server_id = r.hget 'serverForRoom', room_guid
      unless assigned_server_id
        assigned_server_id = find_least_loaded_server_id
        r.hset 'serverForRoom', room_guid, assigned_server_id
      end
      assigned_server_id
    end

    def find_least_loaded_server_id
      sorted_servers = active_servers.sort_by { |server| server['user_count'] }
      sorted_servers.first['server_id']
    end

  end
end