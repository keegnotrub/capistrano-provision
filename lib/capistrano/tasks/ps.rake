namespace :ps do
  task :list do
    on release_roles(:all) do |host|
      memory = capture(:free, '-hm', strip: false)
      uptime = capture(:uptime, '-p', strip: false)
      puts "===#{host.roles_array.join('/')}: #{host.hostname}\n#{memory}#{uptime}\n"
    end
  end

  desc 'Restart service(s)'
  task :restart do
    on release_roles(:all) do |host|
      host.roles.to_a.each do |role|
        execute :sv, "t #{role}"
      end
    end
  end

  after 'deploy:finished', 'ps:restart'
end

desc "List service(s)"
task ps: %w[ps:list]
