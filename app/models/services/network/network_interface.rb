class Services::Network::NetworkInterface < Service
  def depends
    [
      { name: "subnet", protocol: Protocols::Subnet },
      { name: "internet", protocol: Protocols::IP }
    ]
  end

  def provides
    [
      { name: "network_interface", protocol: Protocols::NetworkInterface }
    ]
  end

  def internal
    true
  end

  def expose
    true
  end

  def protocol
    "Protocols::NetworkInterface"
  end
end
