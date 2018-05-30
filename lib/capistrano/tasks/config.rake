namespace :config do
  task :list do
    on fetch(:migration_servers) do
      within shared_path do
        puts capture(:env, '-i chpst -e .env printenv', strip: false)
      end
    end
  end

  desc "Edit config variable, cap config:edit key=RAILS_ENV"
  task :edit do
    key = ENV['key']
    ask(:key_value, echo: false)
    value = fetch(:key_value)
    on release_roles(:all) do |host|
      upload! StringIO.new(value), "/tmp/#{key}"
      within "#{shared_path}/.env" do
        execute :mv, "/tmp/#{key} #{key}"
        execute :chmod, "600 #{key}"
      end
    end    
  end

  desc "Get config variable, cap config:get key=RAILS_ENV"
  task :get do
    key = ENV['key']
    on fetch(:migration_servers) do
      within shared_path do
        puts capture(:env, "-i chpst -e .env printenv #{key}", strip: false)
      end
    end
  end

  desc "Set config variable, cap config:set key=RAILS_ENV value=staging"
  task :set do
    key = ENV['key']
    value = ENV['value']
    on release_roles(:all) do |host|
      upload! StringIO.new(value), "/tmp/#{key}"
      within "#{shared_path}/.env" do
        execute :mv, "/tmp/#{key} #{key}"
        execute :chmod, "600 #{key}"
      end
    end    
  end

  desc "Unset config variable, cap config:unset key=RAILS_ENV"
  task :unset do
    key = ENV['key']
    on release_roles(:all) do |host|
      within "#{shared_path}/.env" do
        execute :rm, key
      end
    end    
  end
end

desc "List config variable(s)"
task config: %w[config:list]
