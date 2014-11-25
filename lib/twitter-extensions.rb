# some exceptions
class NotImportantException < Exception ; end
class FilteredTweetException < Exception ; end
class RudeTweetException < FilteredTweetException ; end

# monkey-patching Twitter::Tweet ...
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

# some (useful?) methods

class Twitter::REST::Client
  def get_current_user
    self.current_user
  rescue Exception => e
    puts "Exception: #{e.message}"
    # best hack:
    ostr = OpenStruct.new
    ostr.id = CONFIG["access_token"].split("-")[0]
    ostr
  end
end