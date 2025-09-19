module ServiceManager
  module GCP
    module Resource
      module GksRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::GCP::ResourceRepresenter

        property :status
        property :version
        property :endpoint
        property :location_type
        property :node_count
        property :creation_time, getter: lambda { |args| self.creation_time.to_datetime.getutc.to_s rescue "" }
        property :locations
        property :zone
        property :mode

      end
    end
  end
end
