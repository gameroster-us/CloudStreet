class AdapterDirectory
  include Enumerable

  attr_accessor :adapters

  def initialize(adapters)
    @adapters = adapters.map do |x|
      AdapterDirectoryInfo.new(x)
    end
  end

  def each
    @adapters.each do |a|
      yield a
    end
  end
end
