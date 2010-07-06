module Worlize
  class PubSub
  
    def self.publish(channel, message)
      if message.class != String
        message = Yajl::Encoder.encode(message)
      end
      redis.publish channel, message
    end
    
    def self.subscribe
      puts "Not yet implemented"
    end

    def self.redis
      @redis ||= begin
        r = Redis.new(
          :host => Worlize.config['redis_servers']['presence']['host'] || 'localhost',
          :port => Worlize.config['redis_servers']['presence']['port'] || 6379
        )
        r.select Worlize.config['redis_servers']['pubsub']['db']
        r
      end
    end
    
  end
end