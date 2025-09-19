module FilerConfigurations
  module CloudResources
    class NetAppService < CloudStreetService

      def self.create(params, &block)
        configuration = FilerConfigurations::CloudResources::NetApp.new(params)
        if configuration.valid?
          configuration.save!
          status Status, :success, configuration, &block
        else
          status Status, :validation_error, configuration, &block
        end
        return configuration
      end

      def self.search(filters, page_params, current_account, &block)
        if filters[:filer_id] && filters[:filer_id].length.eql?(36) && filters[:filer_id].split("-").length.eql?(5)
          configurations = current_account.filer_configurations.net_app.includes(:vpc).includes(:security_group).where(filer_id: filters[:filer_id])
          configurations = configurations.where(vpc_id: filters[:vpc_id]) if filters[:vpc_id].present?

          configurations, total_records = apply_pagination(configurations, page_params)

          status Status, :success, [configurations, total_records], &block
        else
          status Status, :validation_error, {}, &block
        end
        return configurations
      end

      def self.update(params, &block)
        configuration = FilerConfigurations::CloudResources::NetApp.find(params[:id])
        configuration.assign_attributes(params)
        if configuration.valid?
          configuration.save!
          status Status, :success, configuration, &block
        else
          status Status, :validation_error, configuration, &block
        end
        return configuration
      end

      def self.delete(id, &block)
        configuration = FilerConfigurations::CloudResources::NetApp.find_by_id(id)
        configuration && configuration.destroy
        status Status, :success, nil, &block
        return configuration
      end
    end
  end
end