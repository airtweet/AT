# hostname: localhost, port: 3306, u: root, p: gogo2011
require "mysql"
require "stripe"

tweet_time = "2012-02-01 17:55:54 -0800"
tweet_user = "@henrykronick"
tweet_user.downcase! # convert twitter user name to all small case letters
tweet_text = "@testairtweet I want a really $mediumcoffee now please"

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
