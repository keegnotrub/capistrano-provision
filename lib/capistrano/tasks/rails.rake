namespace :rails do
  desc "Run rake task, cap rails:rake task=db:seed"
  task :rake do
    on fetch(:migration_servers) do
      within current_path do
        execute :rake, ENV['task']
      end
    end
  end

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

  desc "Tail rails logs"
  task :log do
    ask(:log_role, 'web')
    log_role = primary(fetch(:log_role))
    on log_role do |host|
      run_with_tunnel('tail -f log/current', host)
    end
  end

  def rails_with_tunnel(command, host)
    command_chruby = "#{fetch(:chruby_exec)} #{fetch(:chruby_ruby)}"
    command_bundle = "bundle exec rails #{command}"
    
    run_with_tunnel("#{command_chruby} -- #{command_bundle}", host)
  end
  
  def run_with_tunnel(command, host)
    tunnel = "ssh -l #{host.user} #{host.hostname}"

    command_cd = "cd #{current_path}"

    exec "#{tunnel} -t '#{command_cd} && #{command}'"
  end
end
