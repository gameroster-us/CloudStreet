class VpcPresenter < CloudStreetService
  def self.check_presense(user, account, attrs, &block)
    vpc = Services::Vpc.fetch_vpc_by_user_access(attrs[:adapter_id], attrs[:region_id], user, account).first

    if vpc
      status VpcStatus, :success, vpc, &block
    else
      status VpcStatus, :not_found, nil, &block
    end
    return vpc
  end
end
VpcPresenter.send(:include, MarketplaceVpcPresenter) if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
