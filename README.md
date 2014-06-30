# micro-spider

A DSL to write web spider. Depend on capybara and capybara-webkit.

# Example

```ruby
require 'micro_spider'
spider = MicroSpider.new

spider.learn do
  site 'http://www.bbc.com'
  entrance '/news'
  
  field :top_story, '#top-story h2 a'
end

spider.crawl

spider.results

```



