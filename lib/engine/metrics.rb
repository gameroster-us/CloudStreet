#
module Engine
  # https://github.com/etsy/statsd/blob/master/docs/metric_types.md
  class Metrics

    # This is the one that should write to statsd, etc
    # CloudStreet::Metrics should write to AMQP, metrics listener will convert
    def self.increment(stat, sample_rate = 1)
      CSLogger.info "Incrementing #{stat}"
      # require 'chump'
      CSLogger.info CloudStreet.statsd.inspect
      CSLogger.info "----"
      # CloudStreet.statsd.increment(stat)
      # ; count stat, 1, sample_rate
    end
  end
end