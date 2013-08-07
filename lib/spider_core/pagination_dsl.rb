module SpiderCore
  module PaginationDSL

    attr_accessor :next_page, :skip_pages

    def keep_eyes_on_next_page(pattern, opts = {}, &block)
      kind = opts[:kind] || :css
      actions << lambda {
        element = first(kind, pattern)
        @next_page = if block_given?
          yield(element)
        else
          element && element[:href]
        end
        @paths.unshift(@next_page) if @next_page
      }
    end

  end
end
