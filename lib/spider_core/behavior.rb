require 'enumerable/lazy' if RUBY_VERSION < '2.0'

module SpiderCore
  module Behavior

    protected

    def scan_all(kind, pattern, opts = {})
      if pattern.is_a?(String)
        elements = all(kind, pattern).lazy
        if opts[:limit] && opts[:limit].to_i > 0
          elements = elements.take(opts[:limit].to_i)
        end
        return elements
      elsif pattern.is_a?(Regexp)
        html.scan(pattern).lazy
      end
    end

    def scan_first(kind, pattern)
      if pattern.is_a?(String)
        first(kind, pattern)
      elsif pattern.is_a?(Regexp)
        html[pattern, 1]
      end
    end

  end
end
