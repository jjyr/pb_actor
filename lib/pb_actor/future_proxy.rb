require 'pb_actor/future'
require 'securerandom'

module PbActor
  class FutureProxy < BasicProxy
    def method_missing method, *args, &blk
      super
      id = SecureRandom.uuid
      Message.send [:future_method_call, id, method, *args], @wr
      Future.new id, @wr, @rd
    end
  end
end
