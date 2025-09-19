module AdapterRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :id
  property :type
  property :info
  property :name
  property :adapter_purpose
  property :display_name
  property :icon
  property :state
  property :provider_name
  property :is_billing
  property :is_backup
  property :is_normal
  property :iam_adapter

  def iam_adapter
      ( self.data['role_arn'].nil? || self.data['role_arn'].empty? ) ? false : true
  end

  def provider_name
    self.class.to_s.gsub('Adapters::','').upcase
  end

  def is_normal
    represented.adapter_purpose == 'billing' ? true :false
  end

  def is_billing
    represented.adapter_purpose == 'billing' ? true :false
  end

  def is_backup
    represented.adapter_purpose == 'backup' ? true :false
  end

  # link :self do |args|
  #   adapter_path(id) if args[:options][:current_user].can_read?(self)
  # end

  # link :remove do |args|
  #   adapter_path(id) if args[:options][:current_user].can_delete?(self)
  # end

  # link :edit do |args|
  #   adapter_path(id) if args[:options][:current_user].can_update?(self)
  # end
end
