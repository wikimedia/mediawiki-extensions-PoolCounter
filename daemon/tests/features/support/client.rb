require 'socket'
require 'timeout'

# Simple wrapper around socket communication with the pool counter.
class Client
  def initialize(hostname = 'localhost', port = 7531)
    @hostname = hostname
    @port = port
    @socket = nil
    @local_port = 0
  end

  def request(command_string)
    connect unless @socket
    @socket.write(command_string + "\n")
  end

  def receive
    raise 'Not connected' unless @socket
    timeout(5) do
      @socket.gets.chop
    end
  end

  def close
    @socket.close if @socket && !@socket.closed?
    @socket = nil
  rescue IOError => e
    # Closing multiple times is ok
    raise unless e.message == 'closed stream'
  end

  private

  def connect
    tries = 5
    @socket = begin
      # We have to retry this sometimes because we're opening in a bunch of
      # threads which can cause EADDRNOTAVAIL.
      sock = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      remote = Socket.pack_sockaddr_in(@port, @hostname)
      # We try and reuse the local port if we can.  The only way to do that is
      # is to bind on 0, copy the ephemeral port we're given, and then rebind
      # on that the next time we open the socket.
      local = Socket.pack_sockaddr_in(@local_port, '127.0.0.1')
      # This wouldn't work unless we requested reusing addresses.  We're lucky
      # pool counter doesn't mind.
      sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)

      sock.bind(local)
      sock.connect(remote)
      @local_port = sock.local_address.ip_port
      sock
    rescue Errno::EADDRNOTAVAIL
      tries -= 1
      retry unless tries == 0
      print "Can't keep trying.  Giving up.\n"
      raise
    end
  end
end
