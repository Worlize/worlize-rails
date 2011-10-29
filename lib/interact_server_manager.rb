module Worlize
  class InteractServerManager
    include Singleton
    
    def initialize
      
    end
    
    def active_servers
      r = redis
      # Redis keeps this list sorted by connected users ascending
      server_ids = r.zrange('serverIds', '0', '-1')
      
      server_info = server_ids.map do |server_id|
        data = r.get("serverStatus:#{server_id}")
        if !data.nil?
          begin
            data = Yajl::Parser.parse(data)
            data['last_checkin'] = DateTime.parse(data['last_checkin'])
          rescue
          end
        end
        data
      end
      
      # If the data is nil, redis has expired the key, meaning that the
      # server has gone down.  So we filter those servers from the list.
      server_info = server_info.select do |data|
        !data.nil?
      end
    end
    
    def active_server_ids
      active_servers.map { |server_info| server_info['server_id'] }
    end
    
    def server_for_room(room_guid)
      r = redis
      r.watch "serverForRoom:#{room_guid}"
      assigned_server_id = r.get "serverForRoom:#{room_guid}"
      
      unless assigned_server_id && active_server_ids.include?(assigned_server_id)
        assigned_server_id = find_least_loaded_server_id
        result = r.multi do
          # expires after 5:00
          r.setex "serverForRoom:#{room_guid}", 300, assigned_server_id
        end
        
        # If the transaction fails, repeat until it doesn't.
        if result.nil?
          return self.server_for_room(room_guid)
        end
      end
      assigned_server_id
    end
    
    def broadcast_to_room(room_guid, message)
      Worlize::PubSub.publish("room:#{room_guid}", message)
    end

    def find_least_loaded_server_id
      server_list = active_servers
      if server_list.empty?
        raise RuntimeError, "There are no interactivity servers running."
      end
    
      server_list[0]['server_id']
    end
    
    def redis
      Worlize::RedisConnectionPool.get_client('room_server_assignments')
    end

  end
end