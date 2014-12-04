Before() do
  @clients = {}
end

After() do
  @clients.values.each(&:close)
end
