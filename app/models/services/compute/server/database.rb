class Services::Compute::Server::Database < Services::Compute::Server
  # store_accessor :data, :aws_id, :instance_id, :region, :ip_address

  def provides
    [
      { name: "database", protocol: Protocols::IP }
    ]
  end

  def startup
    provision
    puts "Start that database"
  end

  def provision
    puts "Provision that database"
  end

  def shutdown
    puts "Shutdown that database"
  end

  def object_restricted?
    true
  end
end
