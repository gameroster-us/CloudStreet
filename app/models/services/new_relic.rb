class Services::NewRelic < Service

  def protocol
    "Protocols::NewRelic"
  end
  def sink
    true
  end

  def provides
    [
      { name: "new_relic", protocol: Protocols::NewRelic }
    ]
  end

  def depends
    []
  end

  def provision
  end
end
