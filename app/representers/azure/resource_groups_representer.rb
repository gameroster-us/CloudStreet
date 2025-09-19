module Azure
  module ResourceGroupsRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :total_records, getter: lambda { |args| args[:options][:total_records]}

    collection(
      :resources,
      class: Azure::ResourceGroup,
      extend: Azure::ResourceGroupRepresenter
    )

    def resources
      collect
    end

  end
end
