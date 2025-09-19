class Metrics
  # Sends an increment (count = 1) for the given stat to the statsd server.
  #
  # @param stat (see #count)
  # @param sample_rate (see #count)
  # @see #count
  def self.increment(stat, sample_rate=1)
    puts "Incrementing #{stat}"
    # require 'chump'
    puts ::CloudStreet.statsd.inspect
    puts "----"
    # CloudStreet.statsd.increment(stat)
    # ; count stat, 1, sample_rate
  end

  # Sends a decrement (count = -1) for the given stat to the statsd server.
  #
  # @param stat (see #count)
  # @param sample_rate (see #count)
  # @see #count
  def self.decrement(stat, sample_rate=1)
  end

  # Sends an arbitrary count for the given stat to the statsd server.
  #
  # @param [String] stat stat name
  # @param [Integer] count count
  # @param [Integer] sample_rate sample rate, 1 for always
  def self.count(stat, count, sample_rate=1)
  end

  # Sends an arbitary gauge value for the given stat to the statsd server.
  #
  # @param [String] stat stat name.
  # @param [Numeric] gauge value.
  # @example Report the current user count:
  #   $statsd.gauge('user.count', User.count)
  def self.gauge(stat, value)
  end

  # Sends a timing (in ms) for the given stat to the statsd server. The
  # sample_rate determines what percentage of the time this report is sent. The
  # statsd server then uses the sample_rate to correctly track the average
  # timing for the stat.
  #
  # @param stat stat name
  # @param [Integer] ms timing in milliseconds
  # @param [Integer] sample_rate sample rate, 1 for always
  def self.timing(stat, ms, sample_rate=1)
  end

  # Reports execution time of the provided block using {#timing}.
  #
  # @param stat (see #timing)
  # @param sample_rate (see #timing)
  # @yield The operation to be timed
  # @see #timing
  # @example Report the time (in ms) taken to activate an account
  #   $statsd.time('account.activate') { @account.activate! }
  def self.time(stat, sample_rate=1)
  end
end
