def execute_interactive_ssh(server, user, command)
  run_locally do
    key     = SSHKit::Backend::Netssh.config.ssh_options[:keys]
    command = %Q(ssh #{server} -i #{key} -t 'sudo su - #{user} -c "#{command}"')

    debug(command)
    exec(command)
  end
end

desc "Load up a console"
task :console do
  execute_interactive_ssh $app_servers.first, "api", "/data/api/current/bin/rails console"
end
