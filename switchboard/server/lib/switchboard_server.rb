require 'config/boot'
require 'switchboard/server/lib/connection'
require 'celluloid/io'

class SwitchboardServer
  include Celluloid::IO
  include Celluloid::Logger

  trap_exit :handler
  def handler actor, reason; end

  def initialize host, port
    info "Starting Peas Switchboard Server on #{Peas.switchboard_server_uri}"

    # Since we included Celluloid::IO, we're actually making a Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    async.run
  end

  finalizer :finalize
  def finalize
    @server.close if @server
  end

  def run
    loop { handle_connection @server.accept }
  end

  # Note how the socket has to be passed around as a method argument. Instance variables in a
  # concurrent Celluloid object are shared between threads. If you store each connection socket as
  # an instance variable then it gets overwritten by each new connection.
  def handle_connection socket
    debug "Current number of tasks: #{tasks.count}"
    connection = Connection.new socket
    connection.dispatch
    socket.close
  rescue
    socket.close
  end

end
