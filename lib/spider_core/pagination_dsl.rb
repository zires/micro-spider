module SpiderCore
  module PaginationDSL

    attr_accessor :next_page, :skip_pages

    def keep_eyes_on_next_page(pattern, opts = {})
      kind = opts[:kind] || :css
      actions << lambda {
        @next_page = first(kind, pattern)[:href] rescue nil
        @paths.unshift(@next_page) if @next_page
      }
    end

  end
end
