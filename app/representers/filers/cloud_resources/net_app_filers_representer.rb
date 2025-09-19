module Filers
  module CloudResources
    module NetAppFilersRepresenter
    include Roar::JSON
    include Roar::Hypermedia

      property :total_records, getter: lambda { |args| args[:options][:total_records]}

      collection(
        :net_app_filers,
        class: Filers::CloudResources::NetApp,
        extend: Filers::CloudResources::NetAppFilerRepresenter
        )

      def net_app_filers
       collect
      end
    end
  end
end