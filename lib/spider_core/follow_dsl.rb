module SpiderCore
  module FollowDSL

    attr_accessor :skip_followers

    def follow(pattern, attr: :href, **opts, &block)
      return unless block_given?

      actions << lambda {
        spider = self.spawn
        spider.learn(&block)
        scan_all(pattern, opts).each do |element|
          next if skip_followers && skip_followers.include?(element[:href])

          spider.skip_set_entrance = false
          spider.entrance(element[attr])
        end
        put(
          "follow::#{pattern}", spider.crawl
        )
      }
    end

  end
end
