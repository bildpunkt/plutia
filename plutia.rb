#!/usr/bin/env ruby
require 'yaml'
require 'twitter'
require 'ostruct'
# for debugging stuff
require 'pp'

# version
version = "v0.0.1"

# config file
conf = YAML.load_file File.expand_path(".", "config.yml")

# Twitter client configuration
client = Twitter::REST::Client.new do |config|
  config.consumer_key = conf['twitter']['consumer_key']
  config.consumer_secret = conf['twitter']['consumer_secret']
  config.access_token = conf['twitter']['access_token']
  config.access_token_secret = conf['twitter']['access_token_secret']
end

streamer = Twitter::Streaming::Client.new do |config|
  config.consumer_key = conf['twitter']['consumer_key']
  config.consumer_secret = conf['twitter']['consumer_secret']
  config.access_token = conf['twitter']['access_token']
  config.access_token_secret = conf['twitter']['access_token_secret']
end

begin
  current_user = client.current_user
rescue Exception => e
  puts "Exception: #{e.message}"
  # best hack:
  current_user = OpenStruct.new
  current_user.id = conf["access_token"].split("-")[0]
end

# lets define some exceptions
class NotImportantException < Exception
end

class Twitter::Tweet
  def raise_if_current_user!
    raise NotImportantException if $current_user.id == self.user.id
  end
  
  def raise_if_retweet!
    raise NotImportantException if self.text.start_with? "RT @"
  end
end

puts "\033[34;1mplutia #{version}\033[0m by pixeldesu"
puts "---------------------------"

# status message for test purposes
begin 
  client.update "Time for a test run!"
rescue Exception => e
  puts "[#{Time.new.to_s}] #{e.message}"
end

# base code: do not touch unless you know what it does
loop do
  streamer.user do |object|
    if object.is_a? Twitter::Tweet
      begin
        object.raise_if_current_user!
        object.raise_if_retweet!
        case object.text
        when /stop following me?/i
          client.update "@#{object.user.screen_name} Okay, but you won't receive any tweets from me afterwards!"
          client.unfollow(object.user.screen_name)
        end
      rescue NotImportantException => e
      rescue Exception => e
        puts "[#{Time.new.to_s}] #{e.message}"
      end
    elsif object.is_a? Twitter::Streaming::Event
      begin
        case object.name
        when :follow
          client.update "@#{object.source.screen_name} Thanks for following me!"
          client.follow(object.source.screen_name)
        when :favorite
          client.update "@#{object.source.screen_name} Thanks for the star, I'll keep it safe!"
        when :unfavorite
          client.update "@#{object.source.screen_name} W-Why are you taking my star away? ;w;"
        when :list_member_added
          client.update "@#{object.source.screen_name} Thanks for adding me to '#{object.target_object.name}'. It's quite roomy here!"
        when :list_member_removed
          client.update "@#{object.source.screen_name} I-I have to go out of '#{object.target_object.name}'? Okay, if you insist ._."
        end
      rescue Exception => e
        puts "[#{Time.new.to_s}] #{e.message}"
      end
    elsif object.is_a? Twitter::Streaming::FriendList
      begin
        pp object
      rescue Exception => e
        puts "[#{Time.new.to_s}] #{e.message}"
      end
    end
  end
  sleep 1
end