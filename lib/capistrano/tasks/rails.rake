namespace :rails do
  desc "Run rails console"
  task :console do
    on fetch(:migration_servers) do |host|
      rails_with_tunnel('console', host)
    end
  end

  desc "Run rails dbconsole"
  task :dbconsole do
    on fetch(:migration_servers) do |host|
      rails_with_tunnel('dbconsole -p', host)
    end
  end

  def rails_with_tunnel(command, host)
    command_chruby = "#{fetch(:chruby_exec)} #{fetch(:chruby_ruby)}"
    command_bundle = "bundle exec rails #{command}"
    command = "#{command_chruby} -- #{command_bundle}"
    command_cd = "cd #{current_path}"
    tunnel = "ssh -l #{host.user} #{host.hostname}"
    exec "#{tunnel} -t '#{command_cd} && #{command}'"
  end
end
