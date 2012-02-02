require 'rubygems'
require 'eventmachine'
require 'em-http'
require 'json'
require "mysql"
require "stripe"

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
          db = Mysql.real_connect("localhost", "root", "gogo2011", "airtweet_db")
          
#************************ Customer Check *************************

customer = db.query("SELECT * FROM customers WHERE customer_twittername = '#{tweet_user}'") # get a row for the twitter name that mentioned our twitter account

customer_info = customer.fetch_row # convert the row to array

if customer_info.nil? == true # check to see if the tweet comes from our customer (who signed up with us)
  puts "Return false" # exit because not in the database
end

#************************ Order Check *************************

tweet_text.split().each do |word| # determine what the person is ordering
  if word.start_with? "$"
    @ordered_item = word
  end
end

item = db.query("SELECT * FROM items WHERE item_twittername = '#{@ordered_item}'") # item will return MySQL::Result object that can either be empty or populated

item_info = item.fetch_row # convert the row to array

if item_info.nil? == true # check to see if we found the maitching item in our database
  puts "Return false" # exit because 1) there was no character with $ or 2) the word with $ is not in the database
end

#************************ Stripe Payment *************************

item_price = item_info[3]
#puts item_price
customer_stripeid = customer_info[4]
#puts customer_stripeid

Stripe.api_key = "4OErpSgQJh78b27kHEWKKnzKEaKGICAW"
Stripe::Charge.create(
  :amount => "#{item_price}",
  :currency => "usd",
  :customer => "#{customer_stripeid}", # obtained with stripe.js
  :description => "Charge for email"
)
#************************ Write to Order Table *************************

customer_id = customer_info[0]
item_id = item_info[0]

write_order = db.query("INSERT INTO orders (customer_id, item_id, order_datetime) VALUES ('#{customer_id}','#{item_id}', NOW())")
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
