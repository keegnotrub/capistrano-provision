namespace :provision do
  desc "Creates the deploy user"
  task :user do
    on provision_roles(:all) do
      next if test("id #{fetch(:deploy_user)} >/dev/null 2>&1")
      
      as user: :root do
        execute :adduser, "--disabled-password --gecos 'Capistrano' #{fetch(:deploy_user)}"
        execute :passwd, "-l #{fetch(:deploy_user)}"        
      end
    end
  end

  desc "Creates the deploy_to directory"
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

  desc "Uploads the environment variables"
  task :env do
    ask(:env_file_or_dir, '.env')
    env_file_or_dir = File.expand_path(fetch(:env_file_or_dir, '.env'))

    entries = {}
    if File.directory?(env_file_or_dir)
      Dir.entries(env_file_or_dir).each do |file|
        next unless file =~ /\A[A-Za-z_0-9]+\z/
        key, val = file, IO.read(file).strip
        entries[key] = val
      end
    elsif File.file?(env_file_or_dir)
      File.read(env_file_or_dir).gsub("\r\n","\n").split("\n") do |line|
        next unless line =~ /\A([A-Za-z_0-9]+)=(.*)\z/
        key, val = $1, $2
        case val
        when /\A'(.*)'\z/
          # Remove single quotes
          entries[key] = $1
        when /\A"(.*)"\z/
          # Remove double quotes and unescape string preserving newline characters
          entries[key] = $1.gsub('\n', "\n").gsub(/\\(.)/, '\1')
        else
          entries[key] = val
        end
      end
    else
      warn 'Enviroment file or directory not found.'
    end
    
    on provision_roles(:all) do
      next if test("sudo [ -d #{shared_path}/.env ]")
      
      as user: :root do
        within shared_path do
          execute :mkdir, '-p .env'
          execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .env"
          execute :chmod, '700 .env'
          entries.each do |key, val|
            upload! StringIO.new(val), "/tmp/#{key}"
            execute :mv, "/tmp/#{key} .env/#{key}"
            execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .env/#{key}"
            execute :chmod, "600 .env/#{key}"
          end
        end
      end
    end
  end
  
  desc "Allows SSH between local and deploy remote user"
  task :ssh do
    ask(:ssh_pub_key, '~/.ssh/id_rsa.pub')
    local_key = File.read(File.expand_path(fetch(:ssh_pub_key, '~/.ssh/id_rsa.pub')))
    
    on provision_roles(:all) do
      next if test("sudo [ -f ~#{fetch(:deploy_user)}/.ssh/authorized_keys ]")
      
      as user: fetch(:deploy_user) do
        within "~#{fetch(:deploy_user)}" do
          execute :mkdir, '-p .ssh'
          execute :chmod, '700 .ssh'
          execute :'ssh-keygen', '-t rsa -b 4096 -f .ssh/id_rsa -N ""'
        end        
      end
      
      upload! StringIO.new(local_key), '/tmp/authorized_keys'
      as user: :root do
        within "~#{fetch(:deploy_user)}" do
          execute :mv, '/tmp/authorized_keys .ssh/authorized_keys'
          execute :chown, "#{fetch(:deploy_user)}:#{fetch(:deploy_user)} .ssh/authorized_keys"
          execute :chmod, '600 .ssh/authorized_keys'
        end
      end
    end
  end

  desc "Update all apt packages"
  task :update do
    on provision_roles(:all) do
      as user: :root do
        with debian_frontend: 'noninteractive' do
          execute :'apt-get', 'update -qq'
        end
      end
    end
  end

  desc "Install required apt packages"
  task :binaries do
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
                    libpq-dev
                    nodejs
                    git
                    runit]

      packages << fetch(:apt_db_client) if host.has_role? "provision_#{fetch(:migration_role)}"
      
      as user: :root do
        with debian_frontend: 'noninteractive' do
          execute :'apt-get', "-qq -y install #{packages.join(' ')}"
        end
      end
    end
  end

  desc "Install ruby-install and chruby"
  task :ruby do
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

  desc "Install runit service(s)"
  task :runit do
    on provision_roles(:all) do |host|
      services = []
      services << :web    if host.has_role? :provision_web
      services << :worker if host.has_role? :provision_worker

      services.each do |service|
        next if test("sudo sv check #{service} >/dev/null")
        
        as user: :root do
          execute :mkdir, "-p /etc/sv/#{service}/log"
        end
        template service, "/etc/sv/#{service}/run"
        template :log, "/etc/sv/#{service}/log/run"

        as user: :root do
          execute :chown, "root:root /etc/sv/#{service}/run /etc/sv/#{service}/log/run"
          execute :chmod, "755 /etc/sv/#{service}/run /etc/sv/#{service}/log/run"
          unless test("[ -L /etc/service/#{service} ]")
            execute :ln, "-s /etc/sv/#{service} /etc/service/#{service}"
          end
          execute <<-CMD
            set -e
            while ! sudo sv check #{service} >/dev/null
              do sleep 1
            done
          CMD
          within "/etc/service/#{service}" do
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

  desc "Memory stats for provisioned server(s)"
  task :stats do
    on provision_roles(:all) do |host|
      memory = capture(:free, '-hm', strip: false)
      puts "#{host.roles.first} [#{host.hostname}]:\n#{memory}"
    end
  end

  desc "Reboots provisioned server(s)"
  task :reboot do
    on provision_roles(:all) do
      as user: :root do
        execute :shutdown, '-r +1'
      end
    end
  end

  def template(name, to)
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

desc "Provisions on Debian based server(s)"
task provision: %w[provision:user
                   provision:dir 
                   provision:env
                   provision:ssh
                   provision:update
                   provision:binaries
                   provision:ruby
                   provision:runit]

namespace :load do
  task :defaults do
    set :deploy_user, fetch(:deploy_user, "deploy")
    set :apt_db_client, fetch(:apt_db_client, "postgresql-client")
    set :web_cmd, fetch(:web_cmd, "bundle exec puma -C config/puma.rb")
    set :worker_cmd, fetch(:worker_cmd, "bundle exec rake jobs:work")
    
    set :bundler_roles, %w[web worker]
    set :assets_roles, %w[web worker]
    set :migration_role, :web

    set :chruby_ruby, "ruby-#{IO.read('.ruby-version').strip}"
    set :chruby_exec, "chpst -e .env chruby-exec"

    append :linked_dirs, ".env"
  end
end
