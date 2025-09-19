class Costs::Storer < CloudStreetService
  attr_reader :adapter, :adapter_id, :account_id, :date
  attr_accessor :parsed_data

  def initialize(adapter, parsed_data, options={})
    @adapter = adapter
    @parsed_data = parsed_data
    @adapter_id = adapter.id
    @account_id = adapter.account_id
    @date       = options[:date]
  end
end
