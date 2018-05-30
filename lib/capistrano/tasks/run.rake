desc "Run command, cap run rails=db:seed"
task :run do
  on fetch(:migration_servers) do
    cmd = fetch(:bundle_bins).find do |bundle_bin|
      ENV.include? bundle_bin
    end
    unless cmd.nil?
      within current_path do
        puts capture(cmd, ENV[cmd])
      end
    else
      warn 'Unable to find command in bundle_bins'
    end
  end
end
