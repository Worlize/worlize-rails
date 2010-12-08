class Admin::StatusController < ApplicationController
  layout 'admin'
  before_filter :require_admin

  def show
    @total_user_count = 0
    @total_session_count = 0
    @total_room_count = 0
    
    server_manager = Worlize::InteractServerManager.instance
    redis = Worlize::RedisConnectionPool.get_client(:presence)
    @interactivity_servers = server_manager.active_servers
    @interactivity_servers.each do |server|
      server['room_count'] = redis.scard("roomsOnServer:#{server['server_id']}")
      @total_user_count += server['user_count']
      @total_session_count += server['session_count']
      @total_room_count += server['room_count']
    end
    
  end
  
end
