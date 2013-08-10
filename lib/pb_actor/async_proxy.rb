module PbActor
  class AsyncProxy < BasicProxy
    def method_missing method, *args, &blk
      super
      Message.send [:async_method_call, nil, method, *args], @wr
      nil
    end
  end
end
