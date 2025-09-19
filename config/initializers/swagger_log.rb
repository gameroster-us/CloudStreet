# Swggerlogger
require 'singleton'
class SwaggerLog < Logger
  include Singleton

  attr_accessor :log_file_name

  def initialize
    super(Rails.root.join("log/swagger.log"))
    self.formatter = formatter()
    self
  end

  def formatter
    Proc.new{|severity, time, progname, msg|
      return '' if msg.blank?
      formatted_severity = sprintf('%-5s', severity.to_s)
      formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')

      if progname.present?
        return "[#{formatted_severity} #{formatted_time} #{progname} #{$$}] #{processed_message(msg)}\n"
      end

      "[#{formatted_severity} #{formatted_time} #{$$}] #{processed_message(msg)}\n"
    }
  end

  private

  def processed_message(msg)
    return msg.map { |k, v| "#{k}='#{v.try(:strip)}'" }.join(' ') if msg.is_a?(Hash)

    msg.to_s.try(:strip)
  end

  class << self
    delegate :error, :debug, :fatal, :info, :warn, :add, :log, to: :instance
  end
end
