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
  def self.clean_desc(x, y)
    y = y.gsub(/\n/, ' ')
    len = 140 - (x + 4)
    y[0..len]
  end

  def self.clean_desc2(y)
    y = y.gsub(/\n/, ' ')
    y.match(/^.{0,140}\b/)[0]
  end

  def smart_truncate(x, len = 135, suffix = '...')
    if x.length <= len
      return x
    else
      return x[0..len + 1].split(' ')[0..-1].join(' ') + suffix
    end
  end

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
          tweet = "New @rOpenSci pkg. %s (v%s) https://cran.r-project.org/package=%s" % [
            package, ver1, package
          ]
          tweet = clean_desc2(tweet + ' ' + res['versions'][ver1]['Title'])

          # if tweet already sent, skip
          mytweets = $twitclient.user_timeline
          logg = []
          mytweets.each do |z|
            logg << tweet.sub(/http.+/, '').casecmp(z.text.sub(/http.+/, '')) == 0
          end
          if logg.include?(0)
            puts 'skipping, tweet already sent'
          else
            # not sent, sending it
            puts 'new package, sending tweet'
            $twitclient.update(tweet)
          end
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
          tweet = "New ver @rOpenSci pkg %s (v%s) https://cran.r-project.org/package=%s -" % [
            package, ver1, package
          ]
          tweet = clean_desc2(tweet + ' ' + res['versions'][ver1]['Title'])

          # if tweet already sent, skip
          mytweets = $twitclient.user_timeline
          logg = []
          mytweets.each do |z|
            logg << tweet.sub(/http.+/, '').casecmp(z.text.sub(/http.+/, '')) == 0
          end
          if logg.include?(0)
            puts 'skipping, tweet already sent'
          else
            # not sent, sending it
            puts 'new package version, sending tweet'
            $twitclient.update(tweet)
          end
        end
      end
    end
  end

  # def self.calculate(package, time_period)
  #   puts 'checking package "' + package + '"'

  #   cn = Faraday.new(:url => 'http://crandb.r-pkg.org/%s/all' % package) do |f|
  #     f.adapter Faraday.default_adapter
  #   end
  #   z = cn.get
  #   if !z.success?
  #     puts 'skipping %s - not on CRAN' % package
  #   else
  #     res = MultiJson.load(z.body)
  #     ver1 = res['versions'].keys.last

  #     # check if a new package
  #     if res['timeline'].length > 1
  #       new_pkg = false
  #     else
  #       new_pkg = true
  #       new_pkg_date = res['timeline'][ver1]
  #       new_pkg_date = Time.parse(new_pkg_date.sub('+00:00', '+01:00'))
  #       new_pkg_date.utc

  #       tweet = "New @rOpenSci pkg. %s (v%s) https://cran.r-project.org/package=%s -" % [
  #         package, ver1, package
  #       ]
  #       tweet = clean_desc2(tweet + ' ' + res['versions'][ver1]['Title'])
  #       return tweet
  #     end

  #     # check if a new version
  #     if new_pkg
  #       puts 'new package, skipping new version check'
  #     else
  #       new_ver_date = res['timeline'][ver1]
  #       new_ver_date = Time.parse(new_ver_date.sub('+00:00', '+01:00'))
  #       new_ver_date.utc

  #       tweet = "New ver @rOpenSci pkg %s (v%s) https://cran.r-project.org/package=%s -" % [
  #         package, ver1, package
  #       ]
  #       tweet = clean_desc2(tweet + ' ' + res['versions'][ver1]['Title'])
  #       return tweet
  #     end
  #   end
  # end

  def self.get_packages
    conn = Faraday.new(:url => 'https://raw.githubusercontent.com/ropensci/roregistry/gh-pages/registry.json') do |f|
      f.adapter Faraday.default_adapter
    end
    x = conn.get
    out = MultiJson.load(x.body)
    pkgs = out['packages'].collect { |x| x['name'] }
    return pkgs
  end

end
