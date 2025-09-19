class EnvironmentWorkflowable
  attr_reader :environment, :action

  def initialize(environment, action)
    @environment = environment
    @action = action
  end

  def build_process
    subprocesses = build_service_subprocesses

    Ruote.define(
      name: "environment/#{@environment.name}/#{action}",
      subprocesses: subprocesses,
      timeout: "10m",
      on_error: 'handle_error',
      on_timeout: 'handle_timeout',
      on_cancel: 'handle_cancel') do
      echo "EnvironmentWorkflowable.build_process:"
      echo '$f:services'
      echo 'setting environment state to starting'
      environment id: '$f:id', method: 'start'
      concurrent_iterator on_val: '$f:services', to_var: 'service' do
        echo "service fields yo"
        echo '${v:service}'
        echo '${v:service.class}'
        echo '${v:service.id}'
        echo '${v:service.method}'
        engine class: "${v:service.class}", id: "${v:service.id}", method: "${v:service.method}", timeout: "1m"
      end
      echo 'setting environment state to running'
      environment id: '$f:id', method: 'run'

      define 'handle_error' do
        echo 'DERP Error: environment provision'
        environment id: '$f:id', method: 'error'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end

      define 'handle_timeout' do
        echo 'DERP Timeout: environment provision'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end

      define 'handle_cancel' do
        echo 'DERP Cancelled: environment provision cancelled'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end
    end
  end

  def stop_workflow
    subprocesses = build_service_subprocesses

    Ruote.define(
      name: "environment/#{@environment.name}/#{action}",
      subprocesses: subprocesses,
      timeout: "10m",
      on_error: 'handle_error',
      on_timeout: 'handle_timeout',
      on_cancel: 'handle_cancel') do
      echo "EnvironmentWorkflowable.stop_workflow:"
      environment id: '$f:id', method: 'stop'
      concurrent_iterator on_val: '$f:services', to_var: 'service' do
        engine class: "${v:service.class}", id: "${v:service.id}", method: "${v:service.method}", timeout: "1m"
      end
      environment id: '$f:id', method: 'done'

      define 'handle_error' do
        echo 'DERP Error: environment provision'
        environment id: '$f:id', method: 'error'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end

      define 'handle_timeout' do
        echo 'DERP Timeout: environment provision'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end

      define 'handle_cancel' do
        echo 'DERP Cancelled: environment provision cancelled'
        # participant ref: 'engine', msg: "Error with process ${wfid}"
      end
    end
  end

  def convert_generic_services
    environment.services.each do |service|
      # If we have a generic server we need to turn it into one of the default provider
      # FIXME: create generic_service scope
      if service.generic
        service.generic_type = service.class.to_s

        klass = environment.default_adapter.services[service.generic_type].constantize
        service.type = klass.to_s
        service.save!
      end
    end
  end

  def launch_build_process
    set_default_adapter
    services = convert_generic_services.map do |x|
      {
        'class' => x.generic ? environment.default_adapter.services[x.class.to_s] : x.class.to_s, 'id' => x.id.to_s,
        'method' => action
      }
    end
    RuoteKit.engine.launch(build_process, { id: environment.id, services: services })
  end

  def launch_stop_workflow
    derps = convert_generic_services
    services = derps.map { |x| { 'class' => x.class.to_s, 'id' => x.id.to_s, 'method' => action } }
    RuoteKit.engine.launch(stop_workflow, { id: environment.id, services: services })
  end


  def build_service_subprocesses
    EnvironmentProvisionable.new(@environment).provision_order.map do |service|
      workflow = ServiceWorkflowable.new(service).workflow
      name = workflow[1]['name'] # FIXME: better way?
      RuoteKit.engine.variables[name] = workflow
      [service.id, name]
    end
  end

  private
    def set_default_adapter
      environment.services.each do |service|
        service.adapter = environment.default_adapter
        service.save!
      end
    end
end
