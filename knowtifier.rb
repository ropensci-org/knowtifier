require 'date'
require 'time'
require 'twitter'
require 'faraday'
require 'multi_json'
require_relative 'helpers'

$twitclient = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV["KNOW_TWITTER_CONSUMER_KEY"]
  config.consumer_secret     = ENV["KNOW_TWITTER_CONSUMER_SECRET"]
  config.access_token        = ENV["KNOW_TWITTER_ACCESS_TOKEN"]
  config.access_token_secret = ENV["KNOW_TWITTER_ACCESS_SECRET"]
end

module Knowtifier
  def self.check(package, time_period)
    puts 'checking package "' + package + '"'

    cn = Faraday.new(:url => 'http://crandb.r-pkg.org/%s/all' % package) do |f|
      f.adapter Faraday.default_adapter
    end
    z = cn.get
    if !z.success?
      puts 'skipping %s - not on CRAN' % package
    else
      res = MultiJson.load(z.body)
      ver1 = res['versions'].keys.last

      # check if a new package
      if res['timeline'].length > 1
        new_pkg = false
      else
        new_pkg = true
        new_pkg_date = res['timeline'][ver1]
        new_pkg_date = Time.parse(new_pkg_date.sub('+00:00', '+01:00'))
        new_pkg_date.utc

        if time_since(new_pkg_date) <= time_period
          puts 'new package, sending tweet'
          tweet = "New @rOpenSci pkg. %s (v.%s) on CRAN (https://cran.rstudio.com/web/packages/%s) src: %s" % [
            package, ver1, package, res['versions'][ver1]['URL']
          ]
          $twitclient.update(tweet)
        end
      end

      # check if a new version
      if new_pkg
        puts 'new package, skipping new version check'
      else
        new_ver_date = res['timeline'][ver1]
        new_ver_date = Time.parse(new_ver_date.sub('+00:00', '+01:00'))
        new_ver_date.utc

        if time_since(new_ver_date) <= time_period
          puts 'new package version, sending tweet'
          tweet = "New ver. @rOpenSci pkg. %s (v.%s) on CRAN (https://cran.rstudio.com/web/packages/%s) src: %s" % [
            package, ver1, package, res['versions'][ver1]['URL']
          ]
          $twitclient.update(tweet)
        end
      end
    end
  end

  def self.get_packages
    conn = Faraday.new(:url => 'https://raw.githubusercontent.com/ropensci/roregistry/master/registry.json') do |f|
      f.adapter Faraday.default_adapter
    end
    x = conn.get
    out = MultiJson.load(x.body)
    pkgs = out['packages'].collect { |x| x['name'] }
    return pkgs
  end

end
