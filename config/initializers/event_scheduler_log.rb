# Event scheduler logger
require 'singleton'
class ESLog < Logger
  include Singleton

  def initialize
    super(Rails.root.join('log/event_scheduler.log'))
    self.formatter = formatter()
    self
  end

  def formatter
    Proc.new{|severity, time, progname, msg|
      formatted_severity = sprintf('%-5s', severity.to_s)
      formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
      "[Event Scheduler #{formatted_severity} #{formatted_time} #{$$}] #{msg.to_s.strip}\n"
    }
  end

  class << self
    delegate :error, :debug, :fatal, :info, :warn, :add, :log, to: :instance
  end
end
