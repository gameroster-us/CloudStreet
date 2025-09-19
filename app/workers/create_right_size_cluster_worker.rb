class CreateRightSizeClusterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :rightsizing, retry: false, backtrace: true

  def perform
    begin
      redshift_instance = create_redshift_cluster
      create_redshift_tables(redshift_instance)
    rescue Exception => error
      raise error
    end
  end

  def create_redshift_cluster
    CSLogger.info "creating redshift clusters........"
    r = Rightsizings::Redshift.new
    r.create_cluster
    r
  end

  def create_redshift_tables(redshift_instance)
    Rightsizings::RedshiftTableService.create_tables(redshift_instance)
  end
end
