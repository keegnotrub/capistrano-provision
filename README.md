# Capistrano::Provision

Ruby on Rails specific provisioning and maintenance tasks for Capistrano v3:

```
cap provision        # Provision Debian based server(s)
cap provision:reboot # Reboot provisioned server(s)
cap deploy:ruby      # Install ruby version
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
```

You'll also want to setup your Capistrano environments in a specific way for provisioning to work:

```ruby
# config/deploy/{staging,production}.rb

## single server for all roles
# server "#{fetch(:deploy_user)}@host", roles: %w[web worker]
# server "admin@host", roles: %w[web worker], no_release: true

## seperate server for each role
# role :web, ["#{fetch(:deploy_user)}@web-host"]
# role :worker, ["#{fetch(:deploy_user)}@worker-host"]
# role :web, ["admin@web-host"], no_release: true
# role :worker, ["admin@worker-host"], no_release: true

## multiple seperate servers for each role
# role :web, ["#{fetch(:deploy_user)}@web-host-1", "#{fetch(:deploy_user)}@web-host2"]
# role :worker, ["#{fetch(:deploy_user)}@worker-host-1", "#{fetch(:deploy_user)}@worker-host2"]
# role :web, ["admin@web-host-1", "admin@web-host-2"], no_release: true
# role :worker, ["admin@worker-host-1", "admin@worker-host-2"], no_release: true
```

## Roles

You'll probably want to adjust your roles per [Rails](https://github.com/capistrano/rails#recommendations) recommendations:

```ruby
# config/deploy.rb

# Defaults to :db
set :migration_role, :web

# Defaults to [:web]
set :assets_roles, [:web, :worker]
```

## Symlinks

You'll probably want to symlink per [Bundler](https://github.com/capistrano/bundler#usage) and [Rails](https://github.com/capistrano/rails#symlinks) recommendations:

```ruby
# config/deploy.rb
append :linked_dirs, ".bundle", "log", "tmp/cache", "tmp/pids", "tmp/sockets"
```

## Assumptions

1. You are using a `.ruby-version` file to set the version of Ruby (default in Rails 5.2+)
2. You provision your database(s) elsewhere and set them via environment variables (`DATABASE_URL`, `REDIS_URL`, etc)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
