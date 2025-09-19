# frozen_string_literal: true

# IdleEc2 services details of the server
class CSIntegration::Server::Services::IdleEC2
  attr_accessor :adapter_id, :account, :params

  def initialize(adapter_id, account, params = {})
    @adapter_id = adapter_id
    @account = account
    @params = params
  end

  def fetch_services
    running_ec2 = ServiceAdviserConfiguration.find_by(account_id: account.id).try(:running_rightsizing_retention_period)
    find_services(running_ec2, params)
  end

  def find_services(running_ec2, params)
    Services::Compute::Server::AWS
      .active_services
      .where(adapter_id: adapter_id, provider_id: params[:instance_id], idle_instance: true)
      .where('provider_created_at < ?', DateTime.now - running_ec2.days)
      .where.not("ignored_from && ARRAY['idle_ec2', 'all']::varchar[]")
  end
end
