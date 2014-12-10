require './features/support/sim'

# Simulator that works like a herd of readers taking the short locks on random
# articles used for rendering.
class ReaderSim < Sim
  def act
    page = rand(100) < 30 ? 'page_very_popular' : 'page' + rand(50).to_s
    result = send_to_client("ACQ4ANY #{page} 2 4 10", %w(LOCKED DONE TIMEOUT QUEUE_FULL))
    return unless result == 'LOCKED'
    sleep(Random.rand * 0.5)
    send_to_client('RELEASE', ['RELEASED'])
  end
end
