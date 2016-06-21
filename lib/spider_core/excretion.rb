require "hamster/hash"

module SpiderCore
  class Excretion < Hamster::Hash
    def is_a?(t)
      if t == ::Hash
        true
      else
        super(t)
      end
    end
  end
end
