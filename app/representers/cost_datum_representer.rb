module CostDatumRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :environments_map, getter: lambda { |args| 
  	hash = {}
  	args[:options][:account].environments.map{|env| hash[env.id] = env.name}
  	hash
  }
  property :adapters_map, getter: lambda { |args| 
  	hash = {}
  	args[:options][:account].adapters.map{|ad| hash[ad.id] = ad.name}
  	hash
  }

  collection(
    :cost_data,
    extend: CostDataRepresenter,
    embedded: false)

  def cost_data
    collect
  end


end