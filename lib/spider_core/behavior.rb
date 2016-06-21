module SpiderCore
  module Behavior

    protected

    def scan_all(pattern, opts = {})
      pattern = handle_pattern(pattern)
      if pattern.is_a?(String)
        elements = all(selector, pattern).lazy
        if opts[:limit] && opts[:limit].to_i > 0
          elements = elements.take(opts[:limit].to_i)
        end
        return elements
      elsif pattern.is_a?(Regexp)
        html.scan(pattern).lazy
      end
    end

    def scan_first(pattern)
      pattern = handle_pattern(pattern)
      if pattern.is_a?(String)
        first(selector, pattern)
      elsif pattern.is_a?(Regexp)
        html[pattern, 1]
      end
    end

    def handle_element(element)
      if element.is_a?(String)
        element
      elsif element.tag_name == 'input'
        element.value
      else
        element.text
      end
    end

    def handle_elements(elements, &block)
      if elements.respond_to?(:map) && block_given?
        elements.map { |element| yield(element) }.force
      elsif elements.respond_to?(:map)
        elements.map { |element| handle_element(element) }.force
      elsif block_given?
        yield(elements)
      else
        handle_element(elements)
      end
    end

    # @example Handle pattern
    #   handle_pattern('.a') # =>'.a'
    #   set :id, 'a'
    #   handle_pattern('.%{id}bc') # =>'.abc'
    def handle_pattern(pattern)
      scan_results = pattern.scan(/(?<=%{)[^}]*(?=})/)
      unless scan_results.empty?
        scan_results.each { |v| pattern = pattern.sub(/%\{#{v}\}/, @setted_variables[v]) }
      end
      pattern
    end

    def put(display, value)
      @current_location = @current_location.put(display, value)
    end

  end
end
