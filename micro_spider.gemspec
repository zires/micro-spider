$:.push File.expand_path("../lib", __FILE__)

require "spider_core/version"

Gem::Specification.new do |s|
  s.name        = "micro_spider"
  s.version     = SpiderCore::VERSION
  s.authors     = ["zires"]
  s.email       = ["zshuaibin@gmail.com"]
  s.homepage    = "https://github.com/zires/micro-spider"
  s.summary     = "A DSL to write web spider."
  s.description = "A DSL to write web spider. Depend on capybara and capybara-webkit."
  s.license     = 'MIT'

  s.files = Dir["{lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "capybara", '~> 2.7', '>= 2.7'
  s.add_dependency "capybara-mechanize", '~> 1.5.0', '>= 1.5.0'
  s.add_dependency "hamster", '~> 3.0.0', '>= 3.0.0'
  s.add_dependency "hashie", '~> 3.4.4', '>= 3.4.0'

  s.add_development_dependency "minitest", '~> 4.7.5', '>= 4.7.5'
  s.add_development_dependency "pry", '~> 0.10.3', '>= 0.10.3'
  s.add_development_dependency "yard", '~> 0.8.7.6', '>= 0.8.7'
  s.add_development_dependency "rake", '~> 11.2.2', '>= 11.2.0'
  s.add_development_dependency "turn", '~> 0.9.7', '>= 0.9.7'
  s.add_development_dependency "sinatra", '~> 1.4.7', '>= 1.4.7'
end
