class Responder
  def initialize(replies, client)
    @replies = replies
    @client = client
  end
  
  # Tweets a reply.
  # @param object [Twitter::Tweet]
  # @param is_mention [Boolean] Is the tweet we're responding to a mention?
  def make_reply(object, is_mention = false)
    sleep 3 + rand(7)
    key = if is_mention
            find_key_by_trigger object.text, true
          else
            find_key_by_trigger object.text
          end
    @client.update "@#{object.user.screen_name} #{@replies[key].sample}", in_reply_to_status: object if key
  end
  
  private
  
  # Finds a key by looking searching the text for trigger regex.
  # @param text [String]
  # @param require_mention [Boolean]
  # @return Key, matching to the text.
  def find_key_by_trigger(text, require_mention = false)
    CONFIG['replies'].each do |reply|
      reply[:triggers].each do |trigger|
        return reply[:key] if text =~ trigger && reply[:require_mention] == require_mention
      end
    end
    nil
  end
end