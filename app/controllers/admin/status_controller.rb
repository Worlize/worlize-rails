class Admin::StatusController < ApplicationController
  layout 'admin'
  before_filter :require_admin

  def show
    @total_user_count = 0
    @total_room_count = 0
    
    server_manager = Worlize::InteractServerManager.instance
    redis = Worlize::RedisConnectionPool.get_client(:room_server_assignments)
    @interactivity_servers = server_manager.active_servers
    
    @interactivity_servers.sort! do |a,b|
      a['server_id'].downcase <=> b['server_id'].downcase
    end
    
    @interactivity_servers.each do |server|
      server['room_count'] = redis.scard("roomsOnServer:#{server['server_id']}")
      @total_user_count += server['user_count']
      @total_room_count += server['room_count']
    end
    
    # Pull redis server stats
    @redis_servers = Worlize.config['redis_servers'].map do |server_name,v|
      Worlize::RedisConnectionPool.get_client(server_name).info.merge('name' => server_name)
    end
    @redis_servers.sort! { |a,b| a['name'] <=> b['name'] }
    
  end
  
end
