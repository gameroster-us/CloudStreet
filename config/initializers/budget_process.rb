# Budget Process logger
require 'singleton'
class BudgetProcess < Logger
  include Singleton

  def initialize
    super(Rails.root.join('log/budget_process.log'))
    self.formatter = formatter()
    self
  end

  def formatter
    Proc.new{|severity, time, progname, msg|
      formatted_severity = sprintf('%-5s', severity.to_s)
      formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
      "[Budget Process #{formatted_severity} #{formatted_time} #{$$}] #{msg.to_s.strip}\n"
    }
  end

  class << self
    delegate :error, :debug, :fatal, :info, :warn, :add, :log, to: :instance
  end
end
