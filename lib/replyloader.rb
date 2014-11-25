require 'yaml'

class ReplyLoader
  
  attr_reader :path
  
  def initialize(path)
    @path = File.expand_path '.', path
  end
  
  def reply_lists
    hsh = {}
    CONFIG['replies'].each do |r|
      begin
        hsh[r[:key]] = YAML.load_file File.expand_path("#{r[:key].to_s}.yml", @path)
      rescue => e
        STDERR.puts "could not load #{r[:key].to_s}.yml: #{e.message}"
      end
    end
    hsh
  end
end