require 'pb_actor/message'
require 'pb_actor/basic_proxy'
require 'pb_actor/async_proxy'
require 'pb_actor/future_proxy'

module PbActor
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
      @async ||= AsyncProxy.new @origin, @pid, @wr, @rd
    end

    def future
      @future ||= FutureProxy.new @origin, @pid, @wr, @rd
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
end
