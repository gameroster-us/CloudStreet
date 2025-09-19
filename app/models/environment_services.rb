class EnvironmentServices
  include Enumerable

  attr_accessor :services

  def initialize(services)
    @services = services.map do |s|
      EnvironmentServiceInfo.new(s)
    end
  end

  def each
    @services.each do |a|
      yield a
    end
  end
end
