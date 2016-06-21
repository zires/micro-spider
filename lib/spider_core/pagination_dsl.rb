module SpiderCore
  module PaginationDSL

    attr_accessor :next_page, :skip_pages

    def keep_eyes_on_next_page(pattern, attr: :href, &block)
      actions << lambda {
        element = first(pattern)
        path = block_given? ? yield(element) : element && element[:href]
        @paths.unshift(path) if path
      }
    end

  end
end
