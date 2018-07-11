namespace :provision do
  ask(:database_url, nil, echo: false)
  
  task :user do
    on provision_roles(:all) do
      next if test("id #{fetch(:deploy_user)} >/dev/null 2>&1")
      
      as user: :root do
        execute :adduser, "--disabled-password --gecos 'Capistrano' #{fetch(:deploy_user)}"
        execute :passwd, "-l #{fetch(:deploy_user)}"        
      end
    end
  end

  task :dir do
    on provision_roles(:all) do
      next if test("sudo [ -d #{fetch(:deploy_to)} ]")
      
      as user: :root do
        execute :mkdir, "-p #{fetch(:deploy_to)}"
        execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} #{fetch(:deploy_to)}"
        execute :chmod, "g+s #{fetch(:deploy_to)}"
        execute :mkdir, "-p #{fetch(:deploy_to)}/shared #{fetch(:deploy_to)}/releases"
        execute :chown, "#{fetch(:deploy_user)} #{fetch(:deploy_to)}/shared #{fetch(:deploy_to)}/releases"
      end
    end
  end

  task :env do
    ask(:secret_key_base, SecureRandom.hex(64), echo: false)
    ask(:port, '8080')
    
    variables = {}
    variables[:RAILS_LOG_TO_STDOUT] = 'enabled'
    variables[:RAILS_SERVE_STATIC_FILES] = 'enabled'
    variables[:LANG] = ENV.fetch('LANG', 'en_US.UTF-8')
      
    on provision_roles(:all) do |host|
      next if test("sudo [ -d #{shared_path}/.env ]")

      variables[:HOME] = capture(:echo, "~#{fetch(:deploy_user)}")
      variables[:USER] = fetch(:deploy_user)
      variables[:RACK_ENV] = fetch(:rails_env)
      variables[:RAILS_ENV] = fetch(:rails_env)
      variables[:DATABASE_URL] = fetch(:database_url)
      variables[:SECRET_KEY_BASE] = fetch(:secret_key_base)
      variables[:PORT] = fetch(:port)

      as user: :root do
        within shared_path do
          execute :mkdir, '-p .env'
          execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .env"
          execute :chmod, '700 .env'
          variables.each do |key, val|
            upload! StringIO.new(val), "/tmp/#{key}"
            execute :mv, "/tmp/#{key} .env/#{key}"
            execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .env/#{key}"
            execute :chmod, "600 .env/#{key}"
          end
        end
      end
    end
  end
  
  task :packages do    
    ask(:apt_packages, apt_packages_default)
    
    on provision_roles(:all) do |host|
      packages = %w[build-essential
                    bison 
                    zlib1g-dev
                    libyaml-dev
                    libssl-dev
                    libgdbm-dev 
                    libreadline-dev
                    libncurses5-dev
                    libffi-dev 
                    nodejs
                    git
                    runit]

      packages += fetch(:apt_packages).split(' ')

      as user: :root do
        with debian_frontend: 'noninteractive' do
          execute :'apt-get', 'update -qq'
          execute :'apt-get', "-qq -y install #{packages.join(' ')}"
        end
      end
    end
  end

  task :chruby do
    src_dir = '/usr/local/src'

    on provision_roles(:all) do
      as user: :root do
        within src_dir do
          %w[ruby-install chruby].each do |package|            
            unless test("[ -d #{src_dir}/#{package} ]")
              execute :git, "clone --depth=1 https://github.com/postmodern/#{package}.git"
            end
            within package do
              execute :git, 'pull'
              execute :make, 'install'
            end
          end
        end        
      end
    end
  end

  task :runit do
    on provision_roles(:all) do |host|
      host.roles_array.each do |role|
        ask("#{role}_cmd", cmd_default(role))
        
        next if test("sudo sv check #{role} >/dev/null")
        
        as user: :root do
          execute :mkdir, "-p /etc/sv/#{role}/log"
        end

        template :run, "/etc/sv/#{role}/run", cmd: fetch("#{role}_cmd")
        template :log, "/etc/sv/#{role}/log/run"

        as user: :root do
          execute :chown, "root:root /etc/sv/#{role}/run /etc/sv/#{role}/log/run"
          execute :chmod, "755 /etc/sv/#{role}/run /etc/sv/#{role}/log/run"
          unless test("[ -L /etc/service/#{role} ]")
            execute :ln, "-s /etc/sv/#{role} /etc/service/#{role}"
          end
          execute <<-CMD
            set -e
            while ! sudo sv check #{role} >/dev/null
              do sleep 1
            done
          CMD
          within "/etc/service/#{role}" do
            ['.', 'log'].each do |path|
              within path do
                execute :chmod, '755 supervise'
                %w[ok control status].each do |file|
                  execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} supervise/#{file}"
                end
              end
            end
          end
        end
      end
    end
  end

  task :ssh do
    ask(:ssh_pub_key, '~/.ssh/id_rsa.pub')
    
    on provision_roles(:all) do |host|
      unless test("sudo [ -f ~#{fetch(:deploy_user)}/.ssh/authorized_keys ]")
        local_key = File.read(File.expand_path(fetch(:ssh_pub_key, '~/.ssh/id_rsa.pub')))
        upload! StringIO.new(local_key), '/tmp/authorized_keys'
        as user: :root do
          within "~#{fetch(:deploy_user)}" do
            execute :mkdir, '-p .ssh'
            execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .ssh"
            execute :chmod, '700 .ssh'
            execute :mv, '/tmp/authorized_keys .ssh/authorized_keys'
            execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .ssh/authorized_keys"
            execute :chmod, '600 .ssh/authorized_keys'
          end
        end
      end
      unless test("sudo [ -f ~#{fetch(:deploy_user)}/.ssh/id_rsa.pub ]")
        as user: fetch(:deploy_user) do
          within "~#{fetch(:deploy_user)}" do
            execute :'ssh-keygen', '-t rsa -b 4096 -f .ssh/id_rsa -N ""'
            deploy_key = capture(:cat, '.ssh/id_rsa.pub', strip: false)
            puts "===#{host.roles_array.join('/')}: #{host.hostname}\n#{deploy_key}\n"
          end        
        end
      end
    end
  end

  desc "Reboot provisioned server(s)"
  task :reboot do
    on provision_roles(:all) do
      as user: :root do
        execute :shutdown, '-r +1'
      end
    end
  end

  def template(name, to, options = {})
    config = Hash.new do |hash, key|
      hash[key] = fetch(key)
    end

    template_path = File.expand_path("../../templates/#{name}.erb", __FILE__)
    template = ERB.new(File.new(template_path).read).result(binding)

    upload! StringIO.new(template), "/tmp/template"
    as user: :root do
      execute :mv,  "/tmp/template #{to}"
    end
  end

  def apt_packages_default
    case URI.parse(fetch(:database_url)).scheme
    when /^mysql/
      'mysql-client libmysqlclient-dev'
    when /^postgres|^postgis/
      'postgresql-client libpq-dev'
    when 'sqlite3'
      'sqlite3 libsqlite3-dev'
    else
      nil
    end
  end

  def cmd_default(role)
    case role
    when [:web, :app]
      'bundle exec rails server'
    when :worker
      'bundle exec rake jobs:work'
    else
      'bundle exec rake'
    end
  end

  def provision_roles(*names)
    options = { filter: :no_release }
    if names.last.is_a? Hash
      names.last.merge(options)
    else
      names << options
    end
    roles(*names)  
  end
end

desc "Provision Debian based server(s)"
task provision: %w[provision:user
                   provision:dir 
                   provision:env
                   provision:packages
                   provision:chruby
                   provision:runit
                   provision:ssh]

namespace :load do
  task :defaults do
    set :deploy_user, fetch(:deploy_user, "deploy")

    set :chruby_ruby, "ruby-#{IO.read('.ruby-version').strip}"
    set :chruby_exec, "chpst -e .env chruby-exec"
    append :chruby_map_bins, "rails"

    append :linked_dirs, ".env"
  end
end
