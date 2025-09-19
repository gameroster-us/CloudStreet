class Services::Container::EKS::AWS < Service
  include Behaviors::Costable::Amazon::EKS
  store_accessor :data, :status, :arn, :role_arn, :endpoint, :vpc_subnet_ids, :vpc_security_groups_ids, :endpoint_public_access, :endpoint_public_access, :endpoint_private_access, :version, :platform_version, :tags, :provider_created_at
  store_accessor :provider_data, :nodegroups, :fargate_profiles

  scope :unused_eks_clusters, -> { where("provider_data->>'is_unused'=?", 'true') }
  scope :unhealthy_eks_clusters, -> { where("provider_data->>'is_unhealthy'=?", 'true') }

  def terminate_service(params={})
    CloudStreet.log "-------------------------------------Terminating(#{self.type}) => #{self.name}"
    region_code = Region.find(self.region_id).code
    eks_client = adapter.connection_eks_client(region_code)
    eks_client.delete_cluster({ name: self.provider_id })
    CloudStreet.log "-------------------------------------Terminated(#{self.type}) => #{self.name}"
  end
end
