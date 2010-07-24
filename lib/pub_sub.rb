module Worlize
  class PubSub
  
    def self.publish(channel, message)
      if message.class != String
        message = Yajl::Encoder.encode(message)
      end
      redis.publish channel, message
    end
    
    def self.subscribe
      raise "Not yet implemented"
    end
    
    def self.redis
      Worlize::RedisConnectionPool.get_client('pubsub')
    end
    
  end
end