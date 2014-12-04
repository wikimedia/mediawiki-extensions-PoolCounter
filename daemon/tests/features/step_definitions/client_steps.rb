Given(/^client (.+)$/) do |name|
  @clients[name] = Client.new
end
When(/^(.+) sends (.+)$/) do |name, text|
  @clients[name].send(text)
end
When(/^(.+) is closed$/) do |name|
  @clients[name].close
end
Then(/^(.+) gets (.+)$/) do |name, text|
  expect(@clients[name].receive).to eq(text)
end
