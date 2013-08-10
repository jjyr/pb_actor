require 'timeout'

module PbActor
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
end
