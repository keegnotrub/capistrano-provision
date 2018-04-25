# Capistrano::provision

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano'
    gem 'capistrano-provision', github: 'keegnotrub/capistrano-provision'

And then execute:

    $ bundle install

## Usage

    # Capfile
    require 'capistrano/provision'


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
    # role :provision_web, ["root@web-host1", "ubuntu@web-host2"], no_release: true
    # role :provision_worker, ["root@worker-host1", "ubuntu@worker-host2"], no_release: true

## Assumptions

1. You want to use [puma](https://github.com/puma/puma) as your web server (default in Rails 5.0+)
2. You want to use [que](https://github.com/chanks/que) as your worker server
3. You are using `.ruby-version` to set the version of ruby (default in Rails 5.2+)
4. You use an `.env` directory in order to set your environment variables (see [envdir](http://thedjbway.b0llix.net/daemontools/envdir.html))
5. You provision your database elsewhere and set it via the `DATABASE_URL` environment variable

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
