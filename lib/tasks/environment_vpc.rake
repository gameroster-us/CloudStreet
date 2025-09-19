namespace :environment_vpc do
  desc "Populating enviroment vpcs"
  task populate_data: :environment do
    CSLogger.info "-------------Populating enviroment and vpc started"
    environments = Environment.where.not(state: 'terminated')
    CSLogger.info "---------------found total #{environments.count} environments"
    environments.each do |environment|
      env_vpc = Vpc.find_by_vpc_id(environment.services.vpcs.first.provider_id) if environment
      CSLogger.info "------for Environment  #{environment.name}------ vpc found #{env_vpc.name}"
      envvpc = EnvironmentVpc.where(environment_id: environment, vpc_id: env_vpc.id).first_or_create!
      CSLogger.info "--------created ----------------#{envvpc.inspect}"
    end
    CSLogger.info '-------Populated association of environment and vpc-----------------completed'
  end
end
