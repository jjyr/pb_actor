module PbActor
  class BasicProxy
    def initialize origin, pid, wr, rd
      @origin, @pid, @wr, @rd = origin, pid, wr, rd
      @alive = true
    end

    def alive?
      if !@alive || (!Process.waitpid @pid, Process::WNOHANG)
        @alive
      else
        @alive = false
      end
    rescue Errno::ECHILD => e
      @alive = false
    end

    def method_missing method, *args, &blk
      raise ArgumentError, 'actor not support block' if blk
      raise DeadActorError, PbActor.dead_actor_msg unless alive?
    end

    def to_s
      "#{self.class}(#{@origin.class})"
    end

    undef send, public_send
  end
end
