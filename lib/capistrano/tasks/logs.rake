desc "View log output"
task :logs do
  ask(:log_role, 'web')
  on primary(fetch(:log_role)) do |host|
    command = 'tail -f log/current'
    command_cd = "cd #{current_path}"
    tunnel = "ssh -l #{host.user} #{host.hostname}"
    exec "#{tunnel} -t '#{command_cd} && #{command}'"
  end
end
