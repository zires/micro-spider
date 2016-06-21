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

  s.add_dependency "capybara"
  s.add_dependency "capybara-mechanize"
  s.add_dependency "hamster"
  s.add_dependency "hashie"

  s.add_development_dependency "minitest"
  s.add_development_dependency "pry"
  s.add_development_dependency "yard"
  s.add_development_dependency "rake"
  s.add_development_dependency "turn"
  s.add_development_dependency "sinatra"
end
