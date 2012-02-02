require 'rubygems'
require 'eventmachine'
require 'em-http'
require 'json'

usage = "#{$0} <user> <password> <track>"
abort usage unless user = ARGV.shift
abort usage unless password = ARGV.shift
abort usage unless keywords= ARGV.shift

def startIt(user,password,keywords)
EventMachine.run do
  http = EventMachine::HttpRequest.new(
  "https://stream.twitter.com/1/statuses/filter.json",
  :connection_timeout => 0,
  :inactivity_timeout => 0
  ).post(
    :head => {'Authorization' => [ user, password ] } , 
    :body => {'track' => keywords}
  )

  buffer = ""
  http.stream do |chunk|
    buffer += chunk
    while line = buffer.slice!(/.+\r?\n/)
      if line.length>5
          tweet=JSON.parse(line)
          tweet_time = Time.new.to_s # get the time of the tweet
          tweet_user = "@" + "#{tweet['user']['screen_name']}" # get the username
          tweet_text = "#{tweet['text']}" # get the text of the tweet
          puts tweet_time
          puts tweet_user
          puts tweet_text
      end
    end

  end
   http.errback {
        puts Time.new.to_s+"Error: "
        puts http.error
   }
end  
    rescue => error
      puts "error rescue "+error.to_s
end

while true
    startIt user,password,keywords
end
