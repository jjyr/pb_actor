require 'timeout'

module PbActor
  class DeadActorError < StandardError
  end

  class BasicProxy
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
        loop do
          type, method, *args = Message.recv cr
          case type
          when :method_call, :async_method_call
            value = @origin.public_send method, *args
            Message.send([:return_value, value], cw) if type == :method_call
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
      Message.send([:method_call, method, *args], @wr)
      type, value = Message.recv @rd
      case type
      when :return_value
        value
      else
        raise "what happend!? receive #{type}"
      end
    end

    def async
      AsyncProxy.new @origin, @pid, @wr
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
    def initialize origin, pid, wr
      @origin, @pid, @wr = origin, pid, wr
    end

    def method_missing method, *args, &blk
      super
      Message.send [:async_method_call, method, *args], @wr
      nil
    end
  end
end
