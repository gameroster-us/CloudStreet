module V2::ReportProfileListObjectRepresenter
  
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :id
  property :name
  property :created_by
  property :provider_config
  property :created_at
  property :updated_at
  property :created_by
  property :linkedto_tenant_or_org
  property :is_default_report_profile

end