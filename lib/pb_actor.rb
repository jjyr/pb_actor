# -*- coding: utf-8 -*-
require "pb_actor/version"

module PbActor
  class << self
    def included base
      base.send :extend, ClassMethods
    end
  end

  module ClassMethods
    def new *args, &blk
      origin = allocate
      proxy = Proxy.new origin
      proxy.async.send :initialize, *args, &blk
      proxy
    end
  end

  class DeadActorError < StandardError
  end
end

require "pb_actor/proxy"
