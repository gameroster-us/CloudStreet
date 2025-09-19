class CSLoggerFormatter < ActiveSupport::Logger::SimpleFormatter
  # This method is invoked when a log event occurs
  def call(severity, timestamp, progname, msg)
    "#{severity}, [#{Time.now.utc.iso8601(3)}] #{Process.pid} TID-#{Thread.current.object_id.to_s(36)} : #{String === msg ? msg : msg.inspect}\n"
  end
end


