namespace :config do
  task :list do
    on fetch(:migration_servers) do
      within current_path do
        puts capture(:env, '-i chpst -e .env printenv', strip: false)
      end
    end
  end

  desc "Edit config variable, cap config:edit key=RAILS_ENV"
  task :edit do
    key = ENV['key']
    key_path = "#{current_path}/.env/#{key}"
    ask(:key_value, echo: false)
    value = fetch(:key_value)
    on release_roles(:all) do |host|
      upload! StringIO.new(value), key_path
      execute :chmod, "600 #{key_path}"
    end    
  end

  desc "Get config variable, cap config:get key=RAILS_ENV"
  task :get do
    key = ENV['key']
    on fetch(:migration_servers) do
      within current_path do
        puts capture(:cat, ".env/#{key}", strip: false)
      end
    end
  end

  desc "Set config variable, cap config:set key=RAILS_ENV value=staging"
  task :set do
    key = ENV['key']
    key_path = "#{current_path}/.env/#{key}"
    value = ENV['value']
    on release_roles(:all) do |host|
      upload! StringIO.new(value), key_path
      execute :chmod, "600 #{key_path}"
    end    
  end

  desc "Unset config variable, cap config:unset key=RAILS_ENV"
  task :unset do
    key = ENV['key']
    key_path = "#{current_path}/.env/#{key}"
    on release_roles(:all) do |host|
      execute :rm, key_path
    end    
  end
end

desc "List config variable(s)"
task config: %w[config:list]
