When(/^I start (\d+) reader like sim(?:s?)$/) do |count|
  count = count.to_i
  count.times do
    sim = ReaderSim.new
    @sims << sim
    sim.start
  end
end
When(/^I start (\d+) search like sim(?:s?)( without per user locks)?$/) do
    |count, without_per_user_locks|
  perform_per_user_locking = !without_per_user_locks
  count = count.to_i
  count.times do
    sim = SearchSim.new(perform_per_user_locking)
    @sims << sim
    sim.start
  end
end
When(/^wait (\d+) seconds$/) do |time_length|
  sleep(time_length.to_i)
end
Then(/^all sims report success$/) do
  @sims.each(&:start_stopping)
  @sims.each(&:stop)
  @sims.each { |sim| expect(sim.error).to eq(nil) }
end
