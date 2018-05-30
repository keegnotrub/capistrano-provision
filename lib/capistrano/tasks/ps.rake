namespace :ps do
  task :list do
    on release_roles(:all) do |host|
      memory = capture(:free, '-hm', strip: false)
      uptime = capture(:uptime, '-p', strip: false)
      packages = capture('/usr/lib/update-notifier/apt-check', '--human-readable', strip: false)
      if test('[ -f /var/run/reboot-required ]')
        packages << '\n'
        packages << capture(:cat, '/var/run/reboot-required', strip: false)
      end
      puts "===#{host.hostname}: #{host.roles.to_a.join('/')}\n#{memory}\n#{uptime}.\n#{packages}"
    end
  end

  desc 'Restart service(s)'
  task :restart do
    on release_roles(:all) do |host|
      execute :sv, 't web'    if host.has_role? :web
      execute :sv, 't worker' if host.has_role? :worker
    end
  end

  after 'deploy:finished', 'ps:restart'
end

desc "List service(s)"
task ps: %w[ps:list]
