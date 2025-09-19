module V2::GCP::ServiceManager::Resource::ImageRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include ::V2::GCP::ServiceManager::ResourceRepresenter

  property :multi_regional_name
  property :gcp_multi_regional_id
  property :deprecation
  property :creation_time, getter: lambda { |args| self.creation_date.to_datetime.getutc.to_s rescue "" }
  property :location_type
  property :disk_size_gb
  property :source
  property :archive_size_gb

  def archive_size_gb
    (archive_size_bytes.to_i / (1024.0 * 1024.0 * 1024.0)).round(5) rescue 0.0
  end

end
