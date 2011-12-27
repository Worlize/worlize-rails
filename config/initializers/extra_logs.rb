class StandaloneLogFormatter
  if RUBY_VERSION.slice(0,3) == '1.8'
    def call(severity, time, progname, msg)
      "%s - pid=%d - %s\n" % [time.strftime('%Y-%m-%d %H:%M:%S %Z'), $$, msg]
    end
  else
    def call(severity, time, progname, msg)
      "%s - pid=%d - %s\n" % [time.strftime('%Y-%m-%d %H:%M:%S.%6N %Z'), $$, msg]
    end
  end
end

module Worlize
  def self.event_logger
    @event_logger
  end
  def self.audit_logger
    @audit_logger
  end

  def self.init_extra_logs
    # Save files with max of 30MiB size, keep the last 10 log files.
    @audit_logger = Logger.new(Rails.root.join('log', 'audit.log'), 10, 30*1024*1024)
    @audit_logger.formatter = StandaloneLogFormatter.new
    @event_logger = Logger.new(Rails.root.join('log', 'event.log'), 10, 30*1024*1024)
    @event_logger.formatter = StandaloneLogFormatter.new
  end
end

Worlize::init_extra_logs