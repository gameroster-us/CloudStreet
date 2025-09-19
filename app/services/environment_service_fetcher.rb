class EnvironmentServiceFetcher < CloudStreetService

  def self.fetch_snapshots(environment, params, &block)
    snapshots = environment.env_snapshots.where.not(state: %w[deleted terminated])
    snapshots = snapshots.volume_snapshots if params[:service_type].eql?('volume')
    snapshots = snapshots.rds_snapshots if params[:service_type].eql?('rds')
    status Status, :success, snapshots, &block
  end

  def self.fetch_clusters(environment, &block)
    clusters = environment.clusters.where.not(state: ["archived","deleted", "terminated"])
    status Status, :success, clusters, &block
  end
end
