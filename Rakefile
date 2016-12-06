require_relative 'knowtifier'

desc "checks for new packages or new releases"
task :run do
  pkgs = Knowtifier.get_packages()
  pkgs.each do |x|
    Knowtifier.check(x, ENV['KNOWTIFIER_MINUTES_SINCE'].to_i)
  end
end

desc "list env vars"
task :envs do
  puts 'minutes since: ' + ENV['KNOWTIFIER_MINUTES_SINCE']
end
