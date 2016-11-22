require_relative 'helper'
require 'fluent/plugin_helper/server'
require 'fluent/plugin/base'
require 'timeout'

require 'serverengine'
require 'fileutils'

class AToFailAtFirstTest < Test::Unit::TestCase
  class Dummy < Fluent::Plugin::TestBase
    helpers :server
  end

  PORT = unused_port

  setup do
    @socket_manager_path = ServerEngine::SocketManager::Server.generate_path
    if @socket_manager_path.is_a?(String) && File.exist?(@socket_manager_path)
      FileUtils.rm_f @socket_manager_path
    end
    @socket_manager_server = ServerEngine::SocketManager::Server.open(@socket_manager_path)
    ENV['SERVERENGINE_SOCKETMANAGER_PATH'] = @socket_manager_path.to_s

    @d = Dummy.new
    @d.start
    @d.after_start
  end

  teardown do
    @d.stopped? || @d.stop
    @d.before_shutdown? || @d.before_shutdown
    @d.shutdown? || @d.shutdown
    @d.after_shutdown? || @d.after_shutdown
    @d.closed? || @d.close
    @d.terminated? || @d.terminate

    @socket_manager_server.close
    if @socket_manager_server.is_a?(String) && File.exist?(@socket_manager_path)
      FileUtils.rm_f @socket_manager_path
    end
  end

  sub_test_case 'a1' do
    test '1' do
      p "1-1"
      t1 = TCPServer.new("::1", PORT)
      t1.do_not_reverse_lookup = true
      p "1-2"
      t2 = TCPServer.new("::1", PORT)
      t2.do_not_reverse_lookup = true
      p "1-3"
      assert_equal 1, 1
    end

    test '2' do
      handler = Class.new(Coolio::TCPSocket) do
        def on_connect
          p(here: "connected")
        end
        def on_read(data)
          p(here: "data", data: data)
        end
      end

      p "2-1"
      loop = Coolio::Loop.new
      c = Class.new(Coolio::TimerWatcher) do
        def initialize
          super(1, true)
        end
        def on_timer
          # ...
        end
      end
      loop.attach(c.new)
      p "2-2"
      th = Thread.new{ loop.run(0.1) }
      p "2-3"
      t1 = TCPServer.new("::1", PORT)
      t1.do_not_reverse_lookup = true
      p "2-4"
      s1 = Coolio::TCPServer.new(t1, nil, handler)
      p "2-5"
      loop.attach(s1)
      p "2-6"
      t2 = TCPServer.new("::1", PORT)
      t2.do_not_reverse_lookup = true
      p "2-7"
      s2 = Coolio::TCPServer.new(t2, nil, handler)
      p "2-8"
      loop.attach(s2)
      p "2-9"
      loop.stop
      th.join
    end
  end

  # sub_test_case '#server_create and #server_create_connection' do
  #   data(
  #     'server_create tcp' => [:server_create, :tcp, {}],
  #     'server_create udp' => [:server_create, :udp, {max_bytes: 128}],
  #     # 'server_create tls' => [:server_create, :tls, {}],
  #     # 'server_create unix' => [:server_create, :unix, {}],
  #     'server_create_connection tcp' => [:server_create, :tcp, {}],
  #     # 'server_create_connection tls' => [:server_create, :tls, {}],
  #     # 'server_create_connection unix' => [:server_create, :unix, {}],
  #   )
  #   test 'cannot create 2 or more servers using same bind address and port if shared option is false' do |(m, proto, kwargs)|
  #     begin
  #       d2 = Dummy.new; d2.start; d2.after_start

  #       assert_nothing_raised do
  #         @d.__send__(m, :myserver, PORT, proto: proto, shared: false, **kwargs){|x| x }
  #       end
  #       assert_raise(Errno::EADDRINUSE) do
  #         d2.__send__(m, :myserver, PORT, proto: proto, **kwargs){|x| x }
  #       end
  #     ensure
  #       d2.stop; d2.before_shutdown; d2.shutdown; d2.after_shutdown; d2.close; d2.terminate
  #     end
  #   end
  # end
end
