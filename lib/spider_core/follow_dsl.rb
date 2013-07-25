module SpiderCore
  module FollowDSL

    attr_accessor :skip_followers

    def follow(pattern, opts = {}, &block)
      return unless block_given?
      kind = opts[:kind] || :css
      actions << lambda {
        spider = self.spawn
        spider.learn(&block)
        scan_all(kind, pattern, opts).each do |element|
          next if skip_followers && skip_followers.include?(element[:href])
          spider.skip_set_entrance = false
          spider.entrance(element[:href])
        end
        current_location[:follow] ||= []
        current_location[:follow] << spider.crawl[:results]
      }
    end

  end
end
