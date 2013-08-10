module PbActor
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
