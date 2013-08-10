module PbActor
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
end
