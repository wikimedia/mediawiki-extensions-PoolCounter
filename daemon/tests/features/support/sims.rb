Before() do
  @sims = []
end

After() do
  @sims.each do |sim|
    expect(sim.started).to eq(false)
  end
end
