# micro-spider

A DSL to write web spider. Depend on capybara and capybara-webkit.

# Example

```ruby
require 'micro_spider'
spider = MicroSpider.new

spider.learn do
  site 'http://www.bbc.com'
  entrance '/news'
  fields :top_stories, 'a.title-link'
end

spider.crawl

spider.get('top_stories')
# or
spider.excretion['/news']['top_stories']

```



