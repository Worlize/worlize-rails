module Worlize
  class RedisConnectionPool
    @clients = {}
  
    def self.get_client(id)
      id = id.to_s
      @clients[id] ||= begin
        r = Redis.new(
          :driver => :hiredis,
          :host => Worlize.config['redis_servers'][id]['host'] || 'localhost',
          :port => Worlize.config['redis_servers'][id]['port'] || 6379
        )
        r.select Worlize.config['redis_servers'][id]['db']
        r
      end
    end
  
  end
end
