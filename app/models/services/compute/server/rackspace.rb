class Services::Compute::Server::Rackspace < Services::Compute::Server

  def startup
    provision
  end

  def provision
    adapter_info = Adapter.for_type(Adapters::Rackspace).first

    aws = Fog::Compute.new(
      provider: 'Rackspace',
      rackspace_username: adapter_info.username,
      rackspace_api_key: adapter_info.api_key,
      version: :v2
    )

    server = aws.servers.create(
      image_id: 'd531a2dd-7ae9-4407-bb5a-e5ea03303d98',
      flavor_id: 4,
      name: "blah"
    )

    server.wait_for do
      print "."
      ready?
    end
  end

  def object_restricted?
    true
  end
end
