# Capistrano::Provision

Provision specific tasks for Capistrano v3:

```
cap provision        # provisions Ubuntu 16.04 LTS server(s)
cap provision:reboot # reboot provisioned server(s)
cap provision:stats  # memory stats on provisioned server(s)
cap deploy:ruby      # deploy:started hook to install Ruby version
cap deploy:restart   # deploy:finished hook to restart server service(s)
cap rails:console    # Run rails console via tunnel
cap rails:dbconsole  # Run rails dbconsole via tunnel
cap rails:log        # Tail rails logs via tunnel
cap rails:rake       # Run rake task, cap rails:rake task=db:seed
```

## Installation

Add these Capistrano gems to your application's Gemfile using `require: false`:

```ruby
# Gemfile
group :development do
  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-provision", git: "https://github.com/keegnotrub/capistrano-provision", require: false
end
```

Run the following command to install the gems:

```
bundle install
```

Then run the generator to create a basic set of configuration files:

```
bundle exec cap install
```

## Usage

Require everything (`chruby`, `bundler`, `rails`, and `provision`):

```ruby
# Capfile
require 'capistrano/provision'
```

Or require just what you need manually:

```ruby
# Capfile
require 'capistrano/chruby'
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'capistrano/provision/provision'
require 'capistrano/provision/deploy'
require 'capistrano/provision/rails'
```

You can tweak some Provision-specific options in `config/deploy.rb`:

```ruby
# config/deploy.rb

# User created for running deploy on the server(s)
# Defaults to 'deploy'
set :deploy_user, 'www'

# Ubuntu apt-get package for client DB connections
# Defaults to 'postgresql-client'
set :apt_db_client, 'mysql-cilent'

# Command for starting a web process
# Defaults to 'bundle exec puma -C config/puma.rb'
set :web_cmd, 'bundle exec unicorn'

# Command for starting a worker process
# Defaults to 'bundle exec rake jobs:work'
set :worker_cmd, 'bundle exec sidekiq'
```

You'll also want to setup your Capistrano environments in a specific way for provisioning to work:

```ruby
# config/deploy/{staging,production}.rb

## single server for both web and worker
# server "#{fetch(:deploy_user)}@host", roles: %w[web worker]
# server "root@host", roles: %w[provision_web provision_worker], no_release: true

## web and worker on seperate server
# role :web, ["#{fetch(:deploy_user)}@web-host"]
# role :worker, ["#{fetch(:deploy_user)}@worker-host"]
# role :provision_web, ["root@web-host"], no_release: true
# role :provision_worker, ["root@worker-host"], no_release: true

## multiple web and worker servers
# role :web, ["#{fetch(:deploy_user)}@web-host1", "#{fetch(:deploy_user)}@web-host2"]
# role :worker, ["#{fetch(:deploy_user)}@worker-host1", "#{fetch(:deploy_user)}@worker-host2"]
# role :provision_web, ["root@web-host1", "root@web-host2"], no_release: true
# role :provision_worker, ["root@worker-host1", "root@worker-host2"], no_release: true
```

## Symlinks

You'll probably want to symlink per [Bundler](https://github.com/capistrano/bundler#usage) and [Rails](https://github.com/capistrano/rails#symlinks) recommendations:

```ruby
# config/deploy.rb
append :linked_dirs, ".bundle", "log", "tmp/cache", "tmp/pids", "tmp/sockets"
```

## Assumptions

1. You plan on deploying a `web` and/or `worker` role for Capistrano
2. You are using a `.ruby-version` file to set the version of Ruby (default in Rails 5.2+)
3. You use an `.env` directory in order to set your environment variables (see [envdir](http://thedjbway.b0llix.net/daemontools/envdir.html))
4. You provision your database(s) elsewhere and set them via environment variables (`DATABASE_URL`, `REDIS_URL`, `MEMCACHE_SERVERS`, etc)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
