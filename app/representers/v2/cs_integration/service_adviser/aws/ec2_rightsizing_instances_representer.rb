module V2::CSIntegration::ServiceAdviser::AWS::EC2RightsizingInstancesRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :instanceid
  property :region
  property :instancetype
  property :vcpu
  property :memory
  property :storage
  property :networkperformance
  property :priceperunit
  property :resizetype
  property :newvcpu
  property :newmemory
  property :newstorage
  property :newnetwork
  property :resizeprice
  property :maxcpu
  property :maxiops
  property :maxnetwork
  property :instancetags
  property :Account
  property :instance_name
  property :region_id
  property :additional_information
  property :costsavedpermonth, getter: lambda { |args|
    rate = args[:options][:user_options][:rate]
    rate.zero? ? self[:costsavedpermonth].to_f : (self[:costsavedpermonth] / (30 * 24) * rate.to_f).to_f
  }
  property :account_id, getter: ->(args) { args[:options][:user_options][:current_account] }
  property :adapter_id, getter: ->(args) { get_adapter_id(args[:options][:user_options][:current_tenant]) }
  property :custom_costsavedpermonth, getter: ->(args) { get_custom_costsavedpermonth(args[:options][:user_options][:current_account]) }
  property :custom_resize_type, getter: ->(args) { get_custom_resize_type(args[:options][:user_options][:current_account]) }
  property :comment_count
  property :service_type
  def instanceid
    self[:instanceid]
  rescue
    nil
  end

  def get_custom_costsavedpermonth(account)
    result = EC2RightSizingExtendResult.where(instanceid: instanceid, account_id: account.id).first
    begin
      result.costsavedpermonth
    rescue
      nil
    end
  end

  def get_custom_resize_type(account)
    result = EC2RightSizingExtendResult.where(instanceid: instanceid, account_id: account.id).first
    begin
      result.resizetype
    rescue
      nil
    end
  end

  def get_adapter_id(tenant)
    account = begin
                self[:Account]
              rescue
                nil
              end
    adapter_ids = tenant.adapters.where("data-> 'aws_account_id'=?", account).normal_adapters.ids
    Services::Compute::Server::AWS.where(adapter_id: adapter_ids, provider_id: instanceid).try(:first).try(:adapter_id)
  end

  def region
    region = begin
               self[:region]
             rescue
               nil
             end
    CommonConstants::REGION_CODES[region.to_sym] if CommonConstants::REGION_CODES.key?(region.to_sym)
  end

  def instancetype
    self[:instancetype]
  rescue
    nil
  end

  def vcpu
    self[:vcpu]
  rescue
    nil
  end

  def memory
    self[:memory]
  rescue
    nil
  end

  def storage
    self[:storage]
  rescue
    nil
  end

  def networkperformance
    self[:networkperformance]
  rescue
    nil
  end

  def priceperunit
    self[:priceperunit]
  rescue
    nil
  end

  def resizetype
    self[:resizetype]
  rescue
    nil
  end

  def newvcpu
    self[:newvcpu]
  rescue
    nil
  end

  def newmemory
    self[:newmemory]
  rescue
    nil
  end

  def newstorage
    self[:newstorage]
  rescue
    nil
  end

  def newnetwork
    self[:newnetwork]
  rescue
    nil
  end

  def resizeprice
    self[:resizeprice]
  rescue
    nil
  end

  def instance_name
    tags = self[:instancetags]
    begin
      tags.split("|").map { |t| t.strip[/^Name\S[^|]*/] }.compact[0].split(':').last
    rescue
      ''
    end
  end

  def maxcpu
    self[:maxcpu]
  rescue
    nil
  end

  def maxiops
    self[:maxiops]
  rescue
    nil
  end

  def maxnetwork
    self[:maxnetwork]
  rescue
    nil
  end

  def instancetags
    tags = begin
             self[:instancetags]
           rescue
             nil
           end
    separated_tags = begin
                       tags.split("| ")
                     rescue
                       nil
                     end
    separated_tags = begin
                       separated_tags.map { |x| x = x.split(":"); {"tag_key": x.first, "tag_value": x.last} }
                     rescue
                       nil
                     end
  end

  def Account
    self[:Account]
  rescue
    nil
  end

  def region_id
    region = begin
               self[:region]
             rescue
               nil
             end
    region_name = CommonConstants::REGION_CODES[region.to_sym] if CommonConstants::REGION_CODES.key?(region.to_sym)
    region_id = Region.find_by_region_name(region_name).try(:id)
  end

  def additional_information
    service = Service.instance_servers.active_services.where(provider_id: self[:instanceid]).first
    info_hash = {}
    info_hash["lifecycle"] = "normal"
    if service.provider_data["lifecycle"].eql?("spot")
      info_hash["lifecycle"] = "spot"
      info_hash["spot_instance_request_id"] = service.provider_data["spot_instance_request_id"]
    end
    info_hash
  end

  def service_type
    'rightsized_ec2'
  end

end
