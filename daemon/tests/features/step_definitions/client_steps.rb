Given(/^client (.+)$/) do |name|
  @clients[name] = Client.new
end
When(/^(.+) sends (.+)$/) do |name, text|
  raise "Unkown client #{name}" unless @clients[name]
  @clients[name].request(text)
end
When(/^(.+) is closed$/) do |name|
  raise "Unkown client #{name}" unless @clients[name]
  @clients[name].close
end
Then(/^(.+) gets (.+)$/) do |name, text|
  raise "Unkown client #{name}" unless @clients[name]
  if text == 'no response'
    # Raise an error if you get a response.  Raise an error if you don't timeout.
    expect(-> { expect(@clients[name].receive).to eq(nil) }).to raise_error(Timeout::Error)
  elsif text.start_with?('/') and text.end_with?('/')
    text = text[1..-2]
    expect(@clients[name].receive).to match(text)
  else
    expect(@clients[name].receive).to eq(text)
  end
end
