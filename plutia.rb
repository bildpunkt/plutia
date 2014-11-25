#!/usr/bin/env ruby
require 'yaml'
require 'twitter'
require 'ostruct'
# for debugging stuff
require 'pp'

# version
version = "v0.1.91"

# config file
conf = YAML.load_file File.expand_path(".", "config.yml")

# reply lists
reply_evening = YAML.load_file File.expand_path(".", "replies/evening.yml")
reply_home = YAML.load_file File.expand_path(".", "replies/home.yml")
reply_hungry = YAML.load_file File.expand_path(".", "replies/hungry.yml")
reply_morning = YAML.load_file File.expand_path(".", "replies/morning.yml")
reply_night = YAML.load_file File.expand_path(".", "replies/night.yml")
reply_tired = YAML.load_file File.expand_path(".", "replies/tired.yml")
reply_work = YAML.load_file File.expand_path(".", "replies/tired.yml")
reply_school = YAML.load_file File.expand_path(".", "replies/tired.yml")
reply_away = YAML.load_file File.expand_path(".", "replies/away.yml")
reply_love = YAML.load_file File.expand_path(".", "replies/love.yml")
reply_freezing = YAML.load_file File.expand_path(".", "replies/freezing.yml")
reply_thanks = YAML.load_file File.expand_path(".", "replies/thanks.yml")

# filter lists
FILTER_WORDS = YAML.load_file File.expand_path(".", "filters/words.yml")
FILTER_RUDE = YAML.load_file File.expand_path(".", "filters/rude_words.yml")

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
  $current_user = client.current_user
rescue Exception => e
  puts "Exception: #{e.message}"
  # best hack:
  $current_user = OpenStruct.new
  $current_user.id = conf["access_token"].split("-")[0]
end

# lets define some exceptions
class NotImportantException < Exception
end

class FilteredTweetException < Exception
end

class RudeTweetException < FilteredTweetException
end

class Twitter::Tweet
  def raise_if_current_user!
    raise NotImportantException if $current_user.id == self.user.id
  end
  
  def raise_if_retweet!
    raise NotImportantException if self.text.start_with? "RT @"
  end
  
  def raise_if_filtered_word!
    FILTER_WORDS.each do |fw|
      if self.text.downcase.include? fw.downcase
        raise FilteredTweetException, "#{self.user.screen_name} triggered filter: '#{fw}'"
      end
    end
  end
  
  def raise_if_rude_word!
    FILTER_RUDE.each do |fr|
      if self.text.downcase.include? fr.downcase
        raise RudeTweetException, "#{self.user.screen_name} triggered filter: '#{fr}'"
      end
    end
  end
  
end

class Twitter::Streaming::Event
  def raise_if_current_user!
    raise NotImportantException if $current_user.id == self.source.id
  end
  
  def raise_if_rude_word!
    FILTER_RUDE.each do |fr|
      if self.target_object.name.include? fr.downcase
        raise RudeTweetException, "#{self.user.screen_name} triggered filter: '#{fr}'"
      end
    end
  end
end

puts "\033[34;1mplutia #{version}\033[0m by pixeldesu"
puts "---------------------------"

# base code: do not touch unless you know what it does
loop do
  streamer.user do |object|
    if object.is_a? Twitter::Tweet
      begin
        object.raise_if_current_user!
        object.raise_if_retweet!
        
        # stuff plutia only will reply to if you mention her
        if object.text.include? "@pluutia"
          object.raise_if_filtered_word!
          object.raise_if_rude_word!
          
          case object.text
          when /unmaid/i
            client.update "@#{object.user.screen_name} Okay, but you won't receive any tweets from me afterwards!", in_reply_to_status:object
            client.block(object.user.screen_name)
            client.unblock(object.user.screen_name)
          when /give me a hug/i, /hug please/i
            sleep 3 + rand(7)
            client.update "@#{object.user.screen_name} *hugs*", in_reply_to_status:object
          when /i love you/i, /love you/i, /ilu/i, /ily/i
            sleep 3 + rand(7)
            client.update "@#{object.user.screen_name} #{reply_love.sample}", in_reply_to_status:object
          when /thanks/i, /thank you/i
            sleep 3 + rand(7)
            client.update "@#{object.user.screen_name} #{reply_thanks.sample}", in_reply_to_status:object
          end
        end
        
        # stuff plutia will reply to if she see's it on her timeline
        case object.text
        when /good morning/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_morning.sample}", in_reply_to_status:object
          
        # good night replies
        when /heading to bed/i, /good night/i, /goodnight/i, /oyasumi/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_night.sample}", in_reply_to_status:object
          
        # good evening replies
        when /good evening/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_evening.sample}", in_reply_to_status:object
        
        # i'm hungry replies
        when /i'm hungry/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_hungry.sample}", in_reply_to_status:object
          
        # i'm home replies
        when /i'm home/i, /tadaima/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_home.sample}", in_reply_to_status:object
          
        # i'm tired replies
        when /i'm sleepy/i, /i'm tired/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_tired.sample}", in_reply_to_status:object
          
        # people need hugs
        when /i want a hug/i, /i need a hug/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} *hugs*", in_reply_to_status:object
          
        # people are feeling cold
        when /i'm cold/i, /i'm freezing/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_freezing.sample}", in_reply_to_status:object
          
        # people go somewhere
        when /off to work/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_work.sample}", in_reply_to_status:object
        when /off to school/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_school.sample}", in_reply_to_status:object
        when /away for/i
          sleep 3 + rand(7)
          client.update "@#{object.user.screen_name} #{reply_away.sample}", in_reply_to_status:object
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