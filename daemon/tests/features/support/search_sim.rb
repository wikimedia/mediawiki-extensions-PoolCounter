require './features/support/sim'

# Simulator that works like someone searching, taking the shortish locks in a large pool.
class SearchSim < Sim
  def initialize(perform_per_user_locking)
    super()
    @perform_per_user_locking = perform_per_user_locking
    if rand(100) < 5
      @user = 'very_big_user'
    else
      @user = 'user_' + rand(10_000).to_s
    end
  end

  def act
    if @perform_per_user_locking
      result = send_to_client("ACQ4ME #{@user} 10 10 0", %w(LOCKED TIMEOUT QUEUE_FULL))
      return unless result == 'LOCKED'
    end
    result = send_to_client('ACQ4ME _search 40 300 10', %w(LOCKED TIMEOUT QUEUE_FULL))
    if result == 'LOCKED'
      sleep(Random.rand * 0.5)
      send_to_client('RELEASE', ['RELEASED'])
    end
    send_to_client('RELEASE', ['RELEASED']) if @perform_per_user_locking
  end
end
