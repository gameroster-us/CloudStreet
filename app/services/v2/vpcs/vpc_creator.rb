module V2
  module Vpcs
    class VpcCreator < CloudStreetService
      def self.create(current_account, vpc_attrs, options, &block)
        begin
          account = fetch Account, account
          user    = fetch User, user
          vpc = CSService::VNET.constantize.init(vpc_attrs, current_account)
          options = options.to_h
          CSLogger.info "New VPC-----------------------------------------------#{vpc.inspect}"
          log_the_errors(vpc, :validation_error, &block) and return vpc unless vpc.valid?
          if vpc.save
            options["vpc"]["resource_group_name"] = vpc.resource_group.name
            Azure::VpcCreateWorker.perform_async(vpc.id, options)
            status VpcStatus, :success, vpc, &block
            return vpc
          else
            log_the_errors(vpc, :failed_to_create, &block) and return vpc unless vpc.valid?
          end
          status ServiceStatus, :success, paginated_services, &block
          return paginated_services
        rescue Exception => e
          CSLogger.error "V2::Vpcs::VpcCreator: create #{e.class} : #{e.message} : #{e.backtrace}"
        end
      end

      def self.log_the_errors(vpc, error_type, error=nil, &block)
        CSLogger.error "Invalid vpc details!"
        CSLogger.error vpc.inspect
        CSLogger.error vpc.errors.inspect

        status VpcStatus, error_type, vpc, &block
      end
    end
  end
end
