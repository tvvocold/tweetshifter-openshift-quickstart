#!/usr/bin/env ruby

require 'bundler/setup'
require 'pp'
require 'multi_json'
require 'yaml'

$stdout.sync = true

Bundler.require(:default)

config_file = File.expand_path('tweetshifter.yml', ENV['OPENSHIFT_DATA_DIR'])
unless File.exists?(config_file)
  config_file = "config.yml"
end
CONFIG = YAML.load(File.read(config_file))

Twitter.configure do |config|
  config.consumer_key       = CONFIG['twitter']['consumer_key']
  config.consumer_secret    = CONFIG['twitter']['consumer_secret']
  config.oauth_token        = CONFIG['twitter']['oauth_token']
  config.oauth_token_secret = CONFIG['twitter']['oauth_token_secret']
end

Target = Faraday.new(:url => CONFIG['tweetshifter']['target']) do |faraday|
  faraday.adapter  Faraday.default_adapter
end

class TweetShifter

  def upload(urls)
    puts "Uploading URLs"
    urls = MultiJson.encode(urls)
    Target.post do |req|
      req.url CONFIG['tweetshifter']['target_path']
      req.headers['Content-Type'] = 'application/json; charset=utf-8'
      req.body = urls
    end
    puts "Upload complete"
  rescue => e
    File.open(File.expand_path("url_#{Time.now.to_i}.json", ENV['OPENSHIFT_DATA_DIR']), 'w') { |file| file.write(urls) }
    puts "Exception in upload: #{e.message}"
  end

  def loop
    puts "******************"
    puts "Fetching favorites"
    Twitter.favorites(:count => CONFIG['tweetshifter']['fetch']).each do |tweet|
      puts "Parsing tweet"
      urls = []
      user = tweet.user
      tweet.urls.each do |url|
        my_url = url.expanded_url || url.url
        urls << { :url => my_url, :id => tweet.id, :tweet => tweet.text, :user => user.name, :description => user.description, :avatar => user.profile_banner_url}
        puts "Captured url: #{my_url}"
      end
      upload(urls)
      Twitter.favorite_destroy(tweet.id)
    end
  rescue => e
    puts "Exception in fetch: #{e.message}"
  end

  def self.start
    @tweetshifter = TweetShifter.new
    while true
      @tweetshifter.loop
      sleep(CONFIG['tweetshifter']['interval'])
    end
  end

end


TweetShifter.start