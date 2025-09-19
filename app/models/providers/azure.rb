class Providers::Azure < Provider
  def self.adapter
    Adapters::Azure
  end
end
