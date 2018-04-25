namespace :deploy do
  desc 'Checks ruby version'
  task :ruby do
    on release_roles(:all) do
      next if test("[ -d ~#{fetch(:deploy_user)}/.rubies/#{fetch(:chruby_ruby)} ]")

      execute :'ruby-install', "--latest --no-install-deps --cleanup #{fetch(:chruby_ruby)}"
      execute :gem, 'install bundler --conservative --no-document'
    end
  end

  desc 'Restarts the service(s)'
  task :restart do
    on release_roles(:all) do |host|
      execute :sv, 't web'    if host.has_role? :web
      execute :sv, 't worker' if host.has_role? :worker
    end
  end

  before 'deploy:started', 'deploy:ruby'
  after 'deploy:finished', 'deploy:restart'
end
