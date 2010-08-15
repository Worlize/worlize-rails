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
    
    def active_server_ids
      active_servers.map { |server_info| server_info['server_id'] }
    end
    
    def server_for_room(room_guid)
      r = Worlize::RedisConnectionPool.get_client('presence')
      assigned_server_id = r.hget 'serverForRoom', room_guid
      
      unless assigned_server_id && active_server_ids.include?(assigned_server_id)
        assigned_server_id = find_least_loaded_server_id
        r.hset 'serverForRoom', room_guid, assigned_server_id
      end
      assigned_server_id
    end
    
    def broadcast_to_room(room_guid, message)
      Worlize::PubSub.publish("room:#{room_guid}", Yajl::Encoder.encode(message))
    end

    def find_least_loaded_server_id
      server_list = active_servers
      if server_list.empty?
        raise RuntimeError, "There are no interactivity servers running."
      end
      sorted_servers = server_list.sort_by { |server| server['session_count'] }
      sorted_servers.first['server_id']
    end

  end
end