# frozen_string_literal: true

# this checks if server is Right Sizing
class CSIntegration::Server::Services::RightSizedInstances
  attr_accessor :adapter_id, :account, :params

  def initialize(adapter_id, account, params = {})
    @adapter_id = adapter_id
    @account = account
    @params = params
  end

  def fetch_services
    config_check = ServiceAdviserConfiguration.find_by(account_id: account.id)
    stopped_ec2_check = config_check.stopped_rightsizing_config_check
    running_ec2_check = config_check.running_rightsizing_config_check
    ec2 = Services::Compute::Server::AWS.active_services
                                        .where(adapter_id: adapter_id, idle_instance: true, provider_id: params[:instance_id])
                                        .first
    find_services(ec2, stopped_ec2_check, running_ec2_check)
  end

  def find_services(ec2, stopped_ec2_check, running_ec2_check)
    options = { adapter_id: adapter_id }
    if ec2.try(:state).eql?('stopped') && !stopped_ec2_check
      []
    elsif ec2.try(:state).eql?('running') && !running_ec2_check
      []
    else
      EC2RightSizing.get_right_sized_instances(options)
                    .where(instanceid: params[:instance_id].first)
    end
  end
end
