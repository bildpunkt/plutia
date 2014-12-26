#!/usr/bin/env ruby
require 'yaml'
require 'twitter'
require 'ostruct'

# for debugging stuff
require 'pp'

# version
PLUTIA_VERSION = "v0.1.91"

# config file
CONFIG = YAML.load_file File.expand_path(".", "config.yml")

# convert the triggers that look like a regex to a (case-insensitive) regex
CONFIG['replies'].each do |reply|
  reply[:triggers].each_with_index do |trigger, i|
    reply[:triggers][i] = /#{$1}/i if /^\/(.*)\/$/ =~ trigger
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'twitter-extensions'
require 'replyloader'
require 'responder'

# Twitter client configuration
client = Twitter::REST::Client.new do |config|
  config.consumer_key = CONFIG['twitter']['consumer_key']
  config.consumer_secret = CONFIG['twitter']['consumer_secret']
  config.access_token = CONFIG['twitter']['access_token']
  config.access_token_secret = CONFIG['twitter']['access_token_secret']
end

# reply lists
loader = ReplyLoader.new './replies'
responder = Responder.new(loader.reply_lists, client)

# filter lists
FILTER_WORDS = YAML.load_file File.expand_path(".", "filters/words.yml")
FILTER_RUDE = YAML.load_file File.expand_path(".", "filters/rude_words.yml")

streamer = Twitter::Streaming::Client.new do |config|
  config.consumer_key = CONFIG['twitter']['consumer_key']
  config.consumer_secret = CONFIG['twitter']['consumer_secret']
  config.access_token = CONFIG['twitter']['access_token']
  config.access_token_secret = CONFIG['twitter']['access_token_secret']
end

$current_user = client.get_current_user

puts "\033[34;1mplutia #{PLUTIA_VERSION}\033[0m by pixeldesu"
puts "---------------------------"

# base code: do not touch unless you know what it does
loop do
  streamer.user do |object|
    if object.is_a? Twitter::Tweet
      begin
        object.raise_if_current_user!
        object.raise_if_retweet!
        
        object.raise_if_filtered_word!
        object.raise_if_rude_word!
        
        # stuff plutia only will reply to if you mention her
          if object.text.include? "@#{CONFIG['twitter']['user_name']}"
            case object.text
            when /unmaid/i
              client.update "@#{object.user.screen_name} Okay, but you won't receive any tweets from me afterwards!", in_reply_to_status: object
              client.block(object.user.screen_name)
              client.unblock(object.user.screen_name)
            else
              responder.make_reply object, true
            end
          else # stuff plutia will reply to if she see's it on her timeline
            responder.make_reply object
          end
      rescue NotImportantException => e
      rescue Exception => e
        puts "[#{Time.new.to_s}] #{e.message}"
      rescue FilteredTweetException => e
        puts "[#{Time.new.to_s}] #{e.message}"
      rescue RudeTweetException => e
        puts "[#{Time.new.to_s}] #{e.message}"
      end
    elsif object.is_a? Twitter::Streaming::Event
      begin
        object.raise_if_current_user!
        
        case object.name
        when :follow
          puts "\033[34;1m[#{Time.new.to_s}] #{object.source.screen_name} followed you!\033[0m"
          sleep 3 + rand(7)
          client.update "@#{object.source.screen_name} Thanks for following me!"
          client.follow(object.source.screen_name)
        when :favorite
          puts "\033[33;1m[#{Time.new.to_s}] #{object.source.screen_name} favorited you!\033[0m"
          sleep 3 + rand(7)
          client.update "@#{object.source.screen_name} Thanks for the star, I'll keep it safe!"
        when :unfavorite
          puts "\033[31;1m[#{Time.new.to_s}] #{object.source.screen_name} unfavorited you!\033[0m"
          sleep 3 + rand(7)
          client.update "@#{object.source.screen_name} W-Why are you taking my star away? ;w;"
        when :list_member_added
          object.raise_if_rude_word!
          puts "\033[36;1m[#{Time.new.to_s}] #{object.source.screen_name} added you to the list '#{object.target_object.name}'!\033[0m"
          sleep 3 + rand(7)
          client.update "@#{object.source.screen_name} Thanks for adding me to '#{object.target_object.name}'. It's quite roomy here!"
        when :list_member_removed
          puts "\033[31;1m[#{Time.new.to_s}] #{object.source.screen_name} removed you from the list '#{object.target_object.name}'!\033[0m"
          sleep 3 + rand(7)
          client.update "@#{object.source.screen_name} I-I have to go out of '#{object.target_object.name}'? Okay, if you insist ._."
        end
      rescue NotImportantException => e
      rescue RudeTweetException => e
        puts "[#{Time.new.to_s}] #{e.message}"
      rescue Exception => e
        puts "[#{Time.new.to_s}] #{e.message}"
      end
    end
  end
  sleep 1
end