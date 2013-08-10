require 'timeout'
require 'securerandom'

module PbActor
  class DeadActorError < StandardError
  end

  module Message
    class << self
      def send msg, wr
        Marshal.dump(msg, wr)
      rescue Errno::EPIPE => e
        raise DeadActorError, 'dead actor call'
      end

      def recv rd
        Marshal.load rd
      end
    end
  end

  class BasicProxy
    def initialize origin, pid, wr, rd
      @origin, @pid, @wr, @rd = origin, pid, wr, rd
    end

    def alive?
      begin
        # Have any other way to check a process status?
        timeout(0.001){Process.wait}
      rescue Timeout::Error => e
      end
      Process.kill(0, @pid) == 1
    rescue Errno::ESRCH, Errno::ECHILD => e
      false
    end

    def method_missing method, *args, &blk
      raise ArgumentError, 'actor not support block' if blk
      raise DeadActorError, 'dead actor call' unless alive?
    end

    def to_s
      "#{self.class}(#{@origin.class})"
    end

    undef send, public_send
  end

  class Proxy < BasicProxy
    def initialize origin
      @origin = origin
      pr, cw = IO.pipe
      cr, pw = IO.pipe
      @pid = fork do
        [pr, pw].each &:close
        @future_values = {}
        loop do
          type, id, method, *args = begin
                                      Message.recv cr
                                    rescue EOFError => e
                                      [:terminate]
                                    end
          case type
          when :async_method_call
            @origin.public_send method, *args
          when :future_method_call
            @future_values[id] = @origin.public_send method, *args
          when :future_value_get
            Message.send(if @future_values.has_key? id
              [:future_value, @future_values.delete(id)]
            else
              [:no_value]
            end, cw)
          when :terminate
            exit
          else
            raise "what happend!? receive #{type.inspect}"
          end
        end
      end
      [cr, cw].each &:close
      @rd = pr
      @wr = pw
    end

    def method_missing method, *args, &blk
      super
      future.method_missing(method, *args).value
    end

    def async
      AsyncProxy.new @origin, @pid, @wr, @rd
    end

    def future
      FutureProxy.new @origin, @pid, @wr, @rd
    end

    def terminate
      Message.send [:terminate], @wr
      Process.wait @pid
      nil
    end

    def terminate!
      Process.kill "KILL", @pid
      Process.wait @pid
      nil
    end
  end

  class AsyncProxy < BasicProxy
    def method_missing method, *args, &blk
      super
      Message.send [:async_method_call, nil, method, *args], @wr
      nil
    end
  end

  class FutureProxy < BasicProxy
    def method_missing method, *args, &blk
      super
      id = SecureRandom.uuid
      Message.send [:future_method_call, id, method, *args], @wr
      Future.new id, @wr, @rd
    end
  end

  class Future
    def initialize id, wr, rd
      @id = id
      @wr= wr
      @rd = rd
    end

    def value
      loop do
        Message.send [:future_value_get, @id], @wr
        type, value = Message.recv @rd
        if type == :future_value
          break value
        else
          sleep 0.01
        end
      end
    end
  end
end
