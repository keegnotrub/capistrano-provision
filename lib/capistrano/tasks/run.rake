desc "Run command, cap run rails=db:seed"
task :run do
  on fetch(:migration_servers) do |host|
    cmd = fetch(:chruby_map_bins).find do |chruby_bin|
      ENV.include? chruby_bin
    end
    unless cmd.nil?
      within current_path do
        puts capture(cmd, ENV[cmd])
      end
    else
      warn 'Unable to find command in chruby_map_bins'
    end
  end
end
