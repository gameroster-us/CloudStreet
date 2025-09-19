module MarketplaceVpcPresenter
  def self.included base
    base.instance_eval do
      def check_presense(user, attrs, &block)
    		unless OrganisationDetail.first.s3_config.present?
    			status VpcStatus, :s3_not_setup, nil, &block
    			return
    		end
        vpc = Services::Vpc.fetch_vpc_by_access(attrs[:adapter_id], attrs[:region_id], user).first

        if vpc
          status VpcStatus, :success, vpc, &block
        else
          status VpcStatus, :not_found, nil, &block
        end           
        return vpc
      end
    end
  end    
end
