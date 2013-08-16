module PbActor
  class Future
    def initialize id, wr, rd
      @id = id
      @wr= wr
      @rd = rd
    end

    def value
      Message.send [:future_value_get, @id], @wr
      type, value = Message.recv @rd
      if type == :future_value
        value
      else
        raise "unknown message type: #{type.inspect} value: #{value.inspect}"
      end
    end
  end
end
