# AKS Representer
module ServiceManager
  module Azure
    module Resource
      module AppServicePlanRepresenter
        include Roar::JSON
        include Roar::Hypermedia
        include ServiceManager::Azure::ResourceRepresenter

        property :operating_system
        property :apps
        property :pricing_tier
        property :zone_redundant
        property :status
        property :price_type

        def pricing_tier
          sku['tier'] + " (#{sku['name']}: #{sku['capacity']})"
        end

        def operating_system
          os == 'linux' ? os : 'windows'
        end

        def price_type
          additional_properties['price_type'] || ''
        end

      end
    end
  end
end
