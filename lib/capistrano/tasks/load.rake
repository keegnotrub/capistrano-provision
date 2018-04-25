namespace :load do
  task :defaults do
    set :deploy_user, fetch(:deploy_user, :deploy)
    
    set :bundler_roles, %w[web worker]
    set :assets_roles, %w[web worker]
    set :migration_role, :web

    set :chruby_ruby, "ruby-#{IO.read('.ruby-version').strip}"
    set :chruby_exec, "chpst -e .env chruby-exec"

    append :linked_dirs, ".env", ".bundle", "log", "tmp/cache", "tmp/pids", "tmp/sockets"
  end
end
