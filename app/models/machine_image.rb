class MachineImage < ApplicationRecord
  include Authority::Abilities
  include Filterable
  attr_accessor :image_name, :instance_types, :new_image, :comment_count
  self.authorizer_name = "OsAuthorizer"
  NON_WINDOWS = "non-windows"

  AMAZON = "amazon"
  SOURCES = ['microsoft','amazon','aws-marketplace']
  UNUSED_AMIS_MINUTES_COUNT = 43200

  belongs_to :adapter
  belongs_to :region
  belongs_to :group, :class_name => "MachineImageGroup",:foreign_key => "machine_image_group_id"
  has_many :organisation_images
  has_many :accounts,through: :organisation_images
  has_and_belongs_to_many :associated_adapters,:join_table=>'adapters_machine_images',class_name: 'Adapter'
  has_and_belongs_to_many :tasks
  #validates :image_id, :uniqueness => {:scope => :region_id}

  alias_attribute :machine_image_group, :group
  accepts_nested_attributes_for :organisation_images, allow_destroy: true

  scope :active,->{ where(active: true) }
  scope :inactive,->{ where(active: false) }
  scope :by_aws_account_id,->(aws_account_id){ where("aws_account_id && :aws_account_id", aws_account_id: "{#{aws_account_id.is_a?(String) ? aws_account_id : aws_account_id.join(',')}}") }

  scope :grouped,->(grouped){grouped ? where.not(machine_image_group_id: nil) : where(machine_image_group_id: nil) }
  scope :filter_by_ami_provider_owner,->(provider){where(image_owner_alias: provider)}
  scope :filter_by_ami_owner,->(owner_id){where(image_owner_id: owner_id)}
  scope :provider_id,->(provider_id){where(adapter_id: provider_id)}
  scope :region_id,->(region_id){where(region_id: region_id)}
  scope :filter_by_image_id, ->(image_id) { where(image_id: image_id) }
  scope :architecture, ->(architecture){where(architecture: architecture)}
  scope :root_device_type, ->(root_device_type){where(root_device_type: root_device_type)}
  scope :virtualization_type, ->(virtualization_type){where(virtualization_type: virtualization_type)}

  scope :keywords,->(description=""){
    after_and_replacement = description.gsub ' and ', '|'
    after_and_or_replacement = (after_and_replacement.gsub ' or ', '|').downcase
    #AND QUERY REF "lower(description) ~* '.*(Linux).*(EBS)' "
    where('(lower(machine_images.image_id) SIMILAR TO  ? OR lower(image_location) SIMILAR TO  ? OR lower(description) SIMILAR TO  ?)',"%("+after_and_or_replacement+")%","%("+after_and_or_replacement+")%","%("+after_and_or_replacement+")%")
    # where('(lower(image_id) LIKE  ? OR lower(image_location) LIKE  ? OR lower(description) LIKE  ? OR lower(group_match) LIKE  ?)',"%"+description.downcase+"%","%"+description.downcase+"%","%"+description.downcase+"%","%"+description.downcase+"%")
  }
  scope :find_with_tags, (lambda do |s_tags, tag_operator, account=nil|
    general_setting = GeneralSetting.find_by(account_id: account || CurrentAccount.account_id)
    if general_setting&.is_tag_case_insensitive
      query = s_tags.each_with_object([]) do |h, memo|
        tag_key = h['tag_key'].gsub("'", "''")
        tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
        memo << "(lower(machine_images.service_tags::text))::jsonb @> lower('#{{tag_key => tag_value}.to_json}')::jsonb "
      end.join(tag_operator)
      s_tags.each do |h|
        query += "OR  (NOT(lower(machine_images.service_tags::text))::jsonb ?& lower('{#{h['tag_key'].gsub("'", "''")}}')::text[]) " if h['tag_value'].eql?(nil)
      end
    else
      query = s_tags.each_with_object([]) do |h, memo|
        tag_key = h['tag_key'].gsub("'", "''")
        tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
        memo << "(machine_images.service_tags)::jsonb @> '#{{tag_key => tag_value}.to_json}'"
      end.join(tag_operator)
      s_tags.each do |h|
        query += "OR  (NOT(machine_images.service_tags)::jsonb ?& '{#{h['tag_key'].gsub("'", "''")}}') " if h['tag_value'].eql?(nil)
      end
    end
    where(query)
  end)

  scope :unused, -> { where("creation_date < ?",(Time.now.utc-UNUSED_AMIS_MINUTES_COUNT.minutes)) }
  
  def owner_adapter(account)
    account_ids = if account.organisation.parent_organisation?
      account.id
    else
      organisations = Organisation.where(id: account.organisation.ancestor_ids)
      organisations.map(&:account).pluck(:id)
    end
    Adapter.where(account_id: account_ids).where("data->'aws_account_id'=?", image_owner_id)&.first
  end


  #scope :unused_amis,->(aws_account_id,adapter_id){ where(image_owner_id: aws_account_id).where.not(image_id: Services::Compute::Server::AWS.where(adapter_id: adapter_id,:state=> ["running","stopped"]).map { |s| s.image_id }).where("creation_date < ?",Date.today-30.days) }
  def self.parse_solr_result(solr_result)
    region_map = Region.aws_region_code_map
    solr_result.each_with_object([]) do |ami, arr|
      ami["region_id"] = region_map[ami["region"]].try(:id)
      next if ami["region_id"].blank?
      ami.delete("type");
      ami.delete("provider");
      ami.delete("region");
      ami.delete("group_name");
      ami.delete("_version_");
      machine_image = new(ami)
      machine_image.cost_by_hour = calculate_and_update_hourly_cost(machine_image)
      machine_image.service_tags = JSON.parse(ami["service_tags"]||"{}")
      arr << machine_image
    end
  end

  def self.unused_amis(options, count_only = false)
    return [] if options[:adapter_id].blank?
    options[:region_id] = Region.aws.map(&:id) if options[:region_id].blank?

    amis_in_use = Services::Compute::Server::AWS.where(adapter_id: options[:adapter_id], region_id: options[:region_id] ,:state=> ["running","stopped"]).map { |s| s.image_id }.uniq

    adapters = Adapters::AWS.includes(:images).available.where(id: options[:adapter_id])
    return [] unless adapters.present?

    organisation_identifier = adapters.first.account.organisation_identifier
    cirion_identifier = 'K0008233'
    maxar_identifier = 'K0008789'
    uniq_aws_account_ids = adapters.map { |a| a.aws_account_id }.uniq

    filters = {
      active: true,
      provider: 'aws',
      not_image_ids: amis_in_use,
      image_owner_ids: uniq_aws_account_ids,
      region: Region.where(id: options[:region_id]).map(&:code)
    }
    service_filter_tags = options.key?(:tags) ? options[:tags] : [{}]
    if count_only
      global_ami_count = {}
      begin
        batch_response = if organisation_identifier.eql?(cirion_identifier)
                           []
                         elsif organisation_identifier.eql?(maxar_identifier)
                           []
                         else
                           batch_unused_ami(amis_in_use, uniq_aws_account_ids, filters, count_only)
                         end
        response = batch_response.flatten.compact.uniq
        account_ids = response.inject([]) { |memo, res| memo.concat(res.keys);memo }.uniq
        account_ids.each do |account_id|
          response.each do |r|
            global_ami_count[account_id] ||= {"amis_count" => 0,"sum_cost_by_hour" => 0}
            global_ami_count[account_id]["amis_count"] += ((r[account_id] && r[account_id]["amis_count"])  || 0)
            global_ami_count[account_id]["sum_cost_by_hour"] += ((r[account_id] && r[account_id]["sum_cost_by_hour"])  || 0)
          end
        end
      rescue CentralApiNotReachable => e
        CloudStreet.log("CentralApiError : #{e.message}")
        Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
      end
      local_ami_count = adapters.each_with_object({}) do |a,h|
        if options[:additional_conditions_value] && options[:additional_conditions_value]["idle_ami"].present?
          ami_days_old = options[:additional_conditions_value]["idle_ami"]["days_old"]
          images = a.images.where("creation_date > ?", Time.now.utc - ami_days_old.days).where(region_id: options[:region_id]).filter_by_ami_owner(a.aws_account_id).where({active: true, is_public: false})
           options[:tags].map { |s| s["tag_value"] = nil if s["tag_value"].eql? "" } unless options[:tags].blank?
          if service_filter_tags.first.blank?
            images = images.find_with_tags(options[:tags], options[:tag_operator], a.account)
          else
            images = images.find_with_tags(service_filter_tags, 'OR', a.account)
            images = images.find_with_tags(options[:tags], options[:tag_operator], a.account)
          end
        elsif options[:tags].first.present?
          images = a.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(a.aws_account_id).where({active: true, is_public: false})
          if service_filter_tags.first.blank?
            images = images.find_with_tags(options[:tags], options[:tag_operator], a.account)
          else
            images = images.find_with_tags(service_filter_tags, 'OR', a.account)
            images = images.find_with_tags(options[:tags], options[:tag_operator], a.account)
          end
        else
          if service_filter_tags.first.blank?
           images = a.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(a.aws_account_id).where({active: true, is_public: false})
          else
            images = a.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(a.aws_account_id).where({active: true, is_public: false}).find_with_tags(service_filter_tags, 'OR', a.account)
          end
        end
        h[a.id] = {
          "count" => images.size,
          "cost_sum" => images.sum(:cost_by_hour)
        }
      end
      adapters.each_with_object({}) do|adapter, memo|
        memo[adapter.id] = {
          "count" => ((local_ami_count[adapter.id] && local_ami_count[adapter.id]["count"]) || 0) + ((global_ami_count[adapter.aws_account_id] && global_ami_count[adapter.aws_account_id]["amis_count"]) ||0),
          "cost_sum" => (local_ami_count[adapter.id] && local_ami_count[adapter.id]["cost_sum"]||0).to_f + (global_ami_count[adapter.aws_account_id] && global_ami_count[adapter.aws_account_id]["sum_cost_by_hour"]||0).to_f
        }
      end
    else
      all_global_amis = {}
      global_fetch_status = :succeeded
      begin
        batch_response = if organisation_identifier.eql?(cirion_identifier)
                           []
                         elsif organisation_identifier.eql?(maxar_identifier)
                           []
                         else
                           batch_unused_ami(amis_in_use, uniq_aws_account_ids, filters)
                         end
        response = batch_response.flatten.compact.uniq
        all_global_amis = parse_solr_result(response).group_by(&:image_owner_id)
      rescue CentralApiNotReachable => e
        global_fetch_status = :failed
        CloudStreet.log("CentralApiError : #{e.message}")
        Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
      end

      adapters.each_with_object({}) do|adapter, memo|
        if options[:additional_conditions_value] && options[:additional_conditions_value]["idle_ami"].present?
          ami_days_old = options[:additional_conditions_value]["idle_ami"]["days_old"]
          local_amis = adapter.images.where("creation_date > ?", Time.now.utc - ami_days_old.days).where(region_id: options[:region_id]).filter_by_ami_owner(adapter.aws_account_id).where({active: true, is_public: false})
          if service_filter_tags.first.blank?
            local_amis = local_amis.find_with_tags(options[:tags], options[:tag_operator], adapter.account)
          else
            local_amis = local_amis.find_with_tags(service_filter_tags, 'OR', adapter.account)
            local_amis = local_amis.find_with_tags(options[:tags], options[:tag_operator], adapter.account)
          end
        elsif options[:tags].try(:first).present?
          local_amis = adapter.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(adapter.aws_account_id).where({active: true, is_public: false})
          if service_filter_tags.first.blank?
            local_amis = local_amis.find_with_tags(options[:tags], options[:tag_operator], adapter.account)
          else
            local_amis = local_amis.find_with_tags(service_filter_tags, 'OR')
            local_amis = local_amis.find_with_tags(options[:tags], options[:tag_operator], adapter.account)
          end
        else
          if service_filter_tags.first.blank?
            local_amis = adapter.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(adapter.aws_account_id).where({active: true, is_public: false})
          else
            local_amis = adapter.images.unused.where(region_id: options[:region_id]).filter_by_ami_owner(adapter.aws_account_id).where({active: true, is_public: false}).find_with_tags(service_filter_tags, 'OR', adapter.account)
          end
        end
        local_images = ServiceAdviser::Ami.new(:private, :succeeded, local_amis.to_a)
        global_amis = all_global_amis[adapter.aws_account_id]
        global_images = ServiceAdviser::Ami.new(:public, global_fetch_status, (global_amis || []))
        memo[adapter.id] = [local_images, global_images]
      end
    end
  end

  def self.provider(provider)
    if ["amazon", "aws-marketplace", "microsoft"].include?(provider)
      return filter_by_ami_provider_owner(provider)
    elsif ["ubuntu","redhat","fedora","debian","gentoo","opensuse"].include?(provider)
      owner_id = get_owner_id_from_provider("ubuntu")
      if owner_id
        return filter_by_ami_owner(owner_id)
      end
    end
    return none
  end

  RULES = {
    [:root_device_type] => {
      ['instance-store'] => ['t2.nano', 't2.micro', 't2.small', 't2.medium',
                            't2.large', 't2.xlarge', 't2.2xlarge', 't3.nano',
                            't3.micro', 't3.small', 't3.medium',
                            't3.large', 't3.xlarge', 't3.2xlarge','m4.large',
                            'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge',
                            'm4.16xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge',
                            'c4.4xlarge', 'c4.8xlarge', 'g3.4xlarge', 'g3.8xlarge',
                            'g3.16xlarge', 'p2.xlarge', 'p2.8xlarge', 'p2.16xlarge',
                            'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge',
                            'r4.8xlarge', 'r4.16xlarge',
                            'm5.large','m5.xlarge','m5.2xlarge','m5.4xlarge','m5.12xlarge','m5.24xlarge','c5.large','c5.xlarge','c5.2xlarge','c5.4xlarge','c5.9xlarge']
    },
    [:architecture] => {
        ['x86_64'] => [],
        ['i386'] => ['t2.large', 't2.xlarge', 't2.2xlarge','t3.large', 't3.xlarge', 't3.2xlarge', 'm4.large', 'm4.xlarge',
                   'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm3.medium',
                   'm3.large', 'm3.xlarge', 'm3.2xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge',
                   'c4.4xlarge', 'c4.8xlarge', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge',
                   'f1.2xlarge', 'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'g2.2xlarge',
                   'g2.8xlarge', 'p2.xlarge', 'p2.8xlarge', 'p2.16xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge',
                   'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge', 'r3.large', 'r3.xlarge', '3.2xlarge', 'r3.4xlarge',
                   'r3.8xlarge', 'x1.16xlarge', 'x1.32xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge',
                   'd2.8xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge', 'i3.large', 'i3.xlarge',
                   'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge',
                   'm5.large','m5.xlarge','m5.2xlarge','m5.4xlarge','m5.12xlarge','m5.24xlarge',
                   'c5.large','c5.xlarge','c5.2xlarge','c5.4xlarge','c5.9xlarge']
    },
    [:virtualization_type] => {
      ['hvm'] => [],
      ['paravirtual'] => ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 't3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge','m4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'f1.2xlarge', 'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'g2.2xlarge', 'g2.8xlarge', 'p2.xlarge', 'p2.8xlarge', 'p2.16xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge', 'r3.large', 'r3.xlarge', '3.2xlarge', 'r3.4xlarge', 'r3.8xlarge', 'x1.16xlarge', 'x1.32xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge', 'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge',
        'm5.large','m5.xlarge','m5.2xlarge','m5.4xlarge','m5.12xlarge','m5.24xlarge','c5.large','c5.xlarge','c5.2xlarge','c5.4xlarge','c5.9xlarge']
    },
    [:platform, :virtualization_type] => {
      [nil, 'hvm'] => ['t1.micro', 'c1.medium', 'c1.xlarge', 't2.large', 't3.large' ,'m2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'm1.small', 'm1.medium', 'm1.large', 'm1.xlarge','m5.12xlarge','m5.24xlarge']
    }
  }

  ALL_INSTANCE_TYPES = [
    't1.micro','t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge',
    't3.nano', 't3.micro', 't3.small', 't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge',
    'm4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm3.medium',
    'm3.large', 'm3.xlarge', 'm3.2xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge',
    'c4.8xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'f1.2xlarge',
    'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'g2.2xlarge', 'g2.8xlarge', 'p2.xlarge',
    'p2.8xlarge', 'p2.16xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge',
    'r4.16xlarge', 'r3.large', 'r3.xlarge', '3.2xlarge', 'r3.4xlarge', 'r3.8xlarge', 'x1.16xlarge',
    'x1.32xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge', 'i2.xlarge', 'i2.2xlarge',
    'i2.4xlarge', 'i2.8xlarge', 'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge', 'i3.8xlarge', 'i3.16xlarge',
    'm5.large','m5.xlarge','m5.2xlarge','m5.4xlarge','m5.12xlarge','m5.24xlarge','c5.large','c5.xlarge','c5.2xlarge','c5.4xlarge','c5.9xlarge'
  ]

  def new_image?
    !!@new_image
  end

  #resource = OrganisationImage/MachineImage
  def self.get_instance_types(resource)
    supported=ALL_INSTANCE_TYPES
    RULES.each do |attr_names, rule_map|
      current_values = attr_names.map { |attr_name| resource.send(attr_name) }
      supported = supported - (rule_map[current_values]||[])
    end
    supported
  end

  def self.get_image_params(raw_image)
    {
      :active=> true,
      :name=> raw_image['name'],
      :architecture=> raw_image['architecture'],
      :description=> raw_image['description'],
      :block_device_mapping=> raw_image['blockDeviceMapping'].to_s,
      :image_id=> raw_image['imageId'],
      :image_location=> raw_image['imageLocation'],
      :image_state=> raw_image['imageState'],
      :image_type=> raw_image['imageType'],
      :image_owner_alias=> raw_image['imageOwnerAlias'],
      :image_owner_id=> raw_image['imageOwnerId'],
      :product_codes=> raw_image['productCodes'].to_s,
      :is_public=> raw_image['isPublic'],
      :kernel_id=> raw_image['kernelId'],
      :platform=> (raw_image['platform']||NON_WINDOWS),
      :ramdisk_id=> raw_image['ramdiskId'],
      :root_device_name=>raw_image['rootDeviceName'],
      :root_device_type=>raw_image['rootDeviceType'],
      :virtualization_type=>raw_image['virtualizationType'],
      :creation_date=>raw_image['creationDate'],
      :cost_by_hour=> calculate_and_update_hourly_cost(raw_image),
      :service_tags => raw_image['tagSet']
    }
  end

  def self.create_machine_image(adapter, region, raw_machine_image, generic_adapter_id)
    image_name = raw_machine_image['imageLocation'].split("amazon/").last
    ami = MachineImage.find_or_create_by(region_id: region.id, image_id: raw_machine_image['imageId']) do|machine_image|
      machine_image.attributes = get_image_params(raw_machine_image).merge({
                                                                             region_id: region.id,
                                                                             adapter_id: adapter.generic_adapter.id
      })
      machine_image.new_image = true
      machine_image.machine_image_group_id = machine_image.find_or_create_machine_image_group
    end
    ami.creation_date = raw_machine_image['creationDate']
    ami.service_tags = raw_machine_image['tagSet']
    ami.is_public = raw_machine_image['isPublic']
    ami.active = true
    # ami.aws_account_id << adapter.aws_account_id unless ami.aws_account_id.include?(adapter.aws_account_id)
    if ami.changed?
      ami.save
    end
    if !ami.new_image? && ami.creation_date.nil?
      ami.update(creation_date: raw_machine_image["creationDate"].try(:to_time),service_tags: raw_machine_image['tagSet'])
    end
    ami
  end

  def find_or_create_machine_image_group
    if self.machine_image_group_id.blank?
      image_match_key = self.image_location.split("amazon/").last
      image_match_key.gsub!("'", "")
      sql = "SELECT id, match_key, region_id,levenshtein('#{image_match_key}', match_key) from machine_image_groups where levenshtein('#{image_match_key}', match_key) <= 3 AND image_owner_id = '#{self.image_owner_id}' AND region_id = '#{self.region_id}' limit 1;"
      res = ActiveRecord::Base.connection.execute(sql)
      if (!res.blank? && res.count > 0)
        self.machine_image_group_id = res.first["id"]
      else
        self.machine_image_group_id = self.create_new_group
      end
      save!
    end
    self.machine_image_group_id
  end

  def create_new_group

    image_name = self.image_location.split("amazon/").last
    matched_architecture = self.image_location.split("amazon/").last.match(/(i386-ebs|i386-gp22|x86-64-gp2|x86-64-ebs)/)
    unique_group_id = Digest::MD5.hexdigest(Marshal::dump({
                                                            matched: matched_architecture ? matched_architecture.captures.first : nil,
                                                            virtualization_type: self.virtualization_type,
                                                            image_owner_alias: self.image_owner_alias,
                                                            root_device_type: self.root_device_type,
                                                            image_owner_id: self.image_owner_id,
                                                            architecture: self.architecture,
                                                            image_type: self.image_type,
                                                            is_public: self.is_public,
                                                            region_id: self.region_id,
                                                            platform: self.platform,
                                                            group_match: image_name
    }))

    group = MachineImageGroup.new(name: unique_group_id, match_key: image_name, region: self.region)
    group.virtualization_type = self.virtualization_type
    group.image_owner_alias = self.image_owner_alias
    group.root_device_type = self.root_device_type
    group.image_owner_id = self.image_owner_id
    group.architecture = self.architecture
    group.image_type = self.image_type
    group.is_public = self.is_public
    group.region_id = self.region_id
    group.platform = self.platform
    if group.save
      return group.id
    else
      return nil
    end
  end

  def adapter_name
    association = AdaptersMachineImage.joins(:adapter).where(machine_image_id: id).first
    association ? association.adapter.try(:name) : nil
  end

  def group_name
    return nil if is_public
    self.group.latest_machine_image.image_location rescue ""
  end

  def group_image_names
    return nil if is_public
    self.group.machine_images.active.pluck(:image_location)
  end

  def assign_best_matching_group(groups)
    unless self.group.present?
      self.group = MachineImageGroup.find_or_create_best_matching_group(self, groups)
      self.save
      OrganisationImage.where({
                                machine_image: self
      }).update_all({
                      machine_image_group_id: self.group.id
      })
    end
  end

  def self.get_owner_id_from_provider(provider)
    case provider
    when "ubuntu"
      "099720109477"
    when "redhat"
      "309956199498"
    when "fedora"
      "125523088429"
    when "debian"
      "379101102735"
    when "gentoo"
      "902460189751"
    when "opensuse"
      "056126556840"
    else
      nil
    end
  end

  def self.get_provider_from_owner_id(owner_id)
    case owner_id
    when "099720109477"
      "ubuntu"
    when "309956199498"
      "redhat"
    when "125523088429"
      "fedora"
    when "379101102735"
      "debian"
    when "902460189751"
      "gentoo"
    when "056126556840"
      "opensuse"
    else
      nil
    end
  end

  def provider
    adapter.type
  end

  def self.findami(ami_id, region)
    image_id = "#{region}-#{ami_id}"
    ami = MachineImage.joins(:region).where(regions: {code: region}, image_id: ami_id).first
    unless ami
      ami = ProviderWrappers::CentralApi::MachineImages.find({id: [image_id]}).first
      if ami
        ami.region_id = Region.where(code: region).pluck(:id).first
      end
    end
    ami
  end

  def machine_image_name
    self.name
  end

  def self.calculate_and_update_hourly_cost(raw_machine_image)
    begin
      if ((raw_machine_image['root_device_type'] == "ebs")|| (raw_machine_image['rootDeviceType'] == "ebs"))
        if raw_machine_image["block_device_mapping"].present?
          if raw_machine_image["block_device_mapping"].is_a?(String)
            bdm = eval(raw_machine_image["block_device_mapping"])
          else
            bdm = raw_machine_image["block_device_mapping"]
          end
        elsif raw_machine_image["blockDeviceMapping"].present?
          if raw_machine_image["blockDeviceMapping"].is_a?(String)
            bdm = eval(raw_machine_image["blockDeviceMapping"])
          else
            bdm = raw_machine_image["blockDeviceMapping"]
          end
        else
          bdm = []
        end

        # Ami cost calculation based on ami attached snapshot total cost
        snapshot_ids = bdm.map{|m| m["snapshotId"]}
        snapshot_query = <<-SQL.squish
          SELECT SUM(cost_by_hour) AS total_cost
          FROM (
            SELECT DISTINCT cost_by_hour, provider_id
            FROM snapshots
            WHERE provider_id IN (?)
              AND cost_by_hour != 0.0
          ) AS distinct_snapshots
        SQL

        # Ensuring snapshot_ids is properly sanitized and formatted to prevent SQL injection attacks
        # -> Using sanitize_sql_array method to safely interpolate the snapshot_ids array into the SQL query.
        sanitized_snapshot_query = Snapshot.send(:sanitize_sql_array, [snapshot_query, snapshot_ids])
        result = Snapshot.connection.execute(sanitized_snapshot_query).first
        total_cost = result['total_cost']
        # total_size = bdm.inject(0) { |sum,h| sum += h["volumeSize"].to_i }
        return total_cost.to_d

        # total_size = bdm.inject(0) { |sum,h| sum += h["volumeSize"].to_i }
        # if raw_machine_image["description"].eql?('This image is created by the AWS Backup service.')
        #   final_cost = (total_size*0.05*0.03)/(24*30).to_d
        # else
        #   final_cost = (total_size*0.05)/(24*30).to_d
        # end
        # return final_cost
      end
      return 0.00
    rescue Exception => e
      return 0.00
    end
  end

  def get_monthly_estimated_cost
    if !self.cost_by_hour.blank? && self[:root_device_type] == "ebs"
      return self.cost_by_hour*24*30 rescue 0.0
    else
      return 0.0
    end
  end

  def self.batch_unused_ami(used_amis, aws_account_ids, filters, only_count = false)
    batch_response = []
    aws_account_ids.each_slice(50) do |account_batch|
      filters[:image_owner_ids] = account_batch
      used_amis.each_slice(100) do |batch|
        filters[:not_image_ids] = batch
        response = ProviderWrappers::CentralApi::MachineImages.find_unused_amis(filters, only_count)
        if only_count
          batch_response << response unless response["numFound"].eql?(0)
        else
          batch_response << response
        end 
      end
    end
    batch_response
  end

  def self.update_archive_status(adapter, region_ids)
    CloudStreet.log(" ========>>>>> Started update_archive_status <<<<<<<<<<==========")
    region_ids.each do |region_id|
      region = Region.find_by_id(region_id)
      amis = adapter.images.where(region_id: region_id, is_public: false, active: true).filter_by_ami_owner(adapter.aws_account_id)
      amis.each do |ami|
        Snapshots::AWS.where(image_reference: "#{region.code}-#{ami[:image_id]}").update_all(archived: true)
      end
      OrganisationImage.archive_templates_and_environments({
        adapter: adapter,
        region: region,
        archived_ami_ids: amis.pluck(:image_id)
      })
      ProviderWrappers::CentralApi::MachineImages.archive_images(amis.pluck(:image_id))
      CloudStreet.log(" <<<<<<<<<<======== ended update_archive_status ========>>>>>")
    end
  rescue CentralApiNotReachable, StandardError => e
    CloudStreet.log(e.class)
    CloudStreet.log(e.message)
    CloudStreet.log(e.backtrace)
    Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
  end

end
