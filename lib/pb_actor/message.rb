module PbActor
  module Message
    class << self
      def send msg, wr
        Marshal.dump(msg, wr)
      rescue Errno::EPIPE => e
        raise DeadActorError, PbActor.dead_actor_msg
      end

      def recv rd
        Marshal.load rd
      rescue EOFError => e
        raise DeadActorError, PbActor.dead_actor_msg
      end
    end
  end
end
