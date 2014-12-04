require 'socket'
require 'timeout'

# Simple wrapper around socket communication with the pool counter.
class Client
  attr_reader :last
  def initialize(hostname = 'localhost', port = 7531)
    @socket = TCPSocket.open(hostname, port)
  end

  def send(command_string)
    @socket.write(command_string + "\n")
  end

  def receive
    timeout(5) do
      @socket.gets.chop
    end
  end

  def close
    @socket.close unless @socket.closed?
  end
end
