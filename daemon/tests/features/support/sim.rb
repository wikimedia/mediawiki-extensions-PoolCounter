# Basic simulation class that does nothing.  Each simulator runs in a standard
# ruby thread so running tens of thousands of them is not advised.
class Sim
  attr_reader :error
  attr_reader :started

  def initialize
    @started = false
    @thread = nil
    @error = nil
    @client = Client.new
  end

  def start
    @started = true
    @thread = Thread.new do
      while @started
        sleep(wait)
        break unless @started
        @error_in_current_action = false
        @track = []
        begin
          act
        rescue Timeout::Error
          @track << 'Timed out!'
          @error_in_current_action = true
        ensure
          close_client
        end
      end
    end
  end

  def wait
    Random.rand * 0.5
  end

  def act
    raise 'Action not defined'
  end

  def start_stopping
    @started = false
    @thread.exit if @thread
  end

  def stop
    start_stopping
    @thread.join
    @client.close if @client
  end

  protected

  def send_to_client(command, expected_results)
    @client.request(command)
    @track << "Sent #{command}"
    result = @client.receive
    @track << "Got #{result}"
    @error_in_current_action |= !expected_results.include?(result)
    result
  end

  def close_client
    @client.close if @client
  end
end
