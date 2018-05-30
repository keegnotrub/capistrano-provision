# Capistrano::Provision

Rails specific provisioning and maintenance tasks for Capistrano v3:

```
cap provision        # Provision Debian based server(s)
cap provision:reboot # Reboot provisioned server(s)
cap config           # List config variable(s)
cap config:edit      # Edit config variable, cap config:edit key=RAILS_ENV
cap config:get       # Get config variable, cap config:get key=RAILS_ENV
cap config:set       # Set config variable, cap config:set key=RAILS_ENV value=staging
cap config:unset     # Unset config variable, cap config:unset key=RAILS_ENV
cap logs             # View log output
cap ps               # List services(s)
cap ps:restart       # Restart service(s)
cap rails:console    # Run rails console
cap rails:dbconsole  # Run rails dbconsole
cap ruby:install     # Install ruby version
cap run              # Run command, cap run rails=db:seed
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
require 'capistrano/provision/config'
require 'capistrano/provision/logs'
require 'capistrano/provision/ps'
require 'capistrano/provision/rails'
require 'capistrano/provision/ruby'
require 'capistrano/provision/run'
```

You can tweak some Provision-specific options in `config/deploy.rb`:

```ruby
# config/deploy.rb

# User created for running deploy on the server(s)
# Defaults to 'deploy'
set :deploy_user, 'www'

# apt package for client DB connections
# Defaults to 'postgresql-client'
set :apt_db_client, 'mysql-cilent'

# Command for starting a web process
# Defaults to 'bundle exec rails server'
set :web_cmd, 'bundle exec puma -C config/puma.rb'

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

1. You plan on deploying a `web` and/or `worker` Capistrano role to a Debian based server
2. You are using a `.ruby-version` file to set the version of Ruby (default in Rails 5.2+)
3. You use an `.env` file or directory in order to set your environment variables (see [dotenv](https://github.com/bkeepers/dotenv) or [envdir](http://thedjbway.b0llix.net/daemontools/envdir.html))
4. You provision your database(s) elsewhere and set them via environment variables (`DATABASE_URL`, `REDIS_URL`, etc)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
