namespace :ruby do
  desc 'Install ruby version'
  task :install do
    on release_roles(:all) do
      next if test("[ -d ~#{fetch(:deploy_user)}/.rubies/#{fetch(:chruby_ruby)} ]")

      execute :'ruby-install', "--latest --no-install-deps --cleanup #{fetch(:chruby_ruby)}"
      execute :'chruby-exec', "#{fetch(:chruby_ruby)} -- gem install bundler --conservative --no-document"
    end
  end
  
  before 'deploy:started', 'ruby:install'
end
