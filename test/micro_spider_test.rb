require 'test_helper'

class MicroSpiderTest < Minitest::Unit::TestCase

  def setup
    @spider = MicroSpider.new
    @spider.logger.level = Logger::WARN
  end

  def test_spider_can_visit_path_with_some_delays
    @spider.delay = 5
    now = Time.now
    @spider.visit('/')
    @spider.visit('/')
    assert_equal 5, @spider.instance_variable_get(:@delay)
    assert (Time.now - now) > 5
  end

  def test_spider_can_get_field
    @spider.learn do
      entrance '/'
      entrance '/a'
      field :name, '#name'
    end
    excretion = @spider.crawl
    assert_equal 'Home', excretion['/']['name']
    assert_equal 'This is a', excretion['/a']['name']
    assert_includes @spider.get('name'), 'Home'
    assert_includes @spider.get('name'), 'This is a'
    assert_equal nil, @spider.get('name1')
  end

  def test_spider_can_follow_lots_of_links
    @spider.entrance('/')
    @spider.follow('.links a') do
      field :name, '#name'
    end
    excretion = @spider.crawl
    excretion['/']["follow::.links a"].each do |path, value|
      case path
      when '/a'
        assert_equal 'This is a', value.get('name')
      when '/b'
        assert_equal 'This is b', value.get('name')
      when '/c'
        assert_equal 'This is c', value.get('name')
      when '/d'
        assert_equal 'This is d', value.get('name')
      end
    end
  end

  def test_spider_can_nest_follow_lots_of_links
    @spider.entrance('/')
    @spider.follow('.links a') do
      follow('.links a') do
        field :name, '#name'
      end
    end
    excretion = @spider.crawl
    excretion['/']["follow::.links a"].each do |key, value|
      value["follow::.links a"].each do |k, v|
        case k
        when '/a'
          assert_equal 'This is a', v.get('name')
        when '/b'
          assert_equal 'This is b', v.get('name')
        when '/c'
          assert_equal 'This is c', v.get('name')
        when '/d'
          assert_equal 'This is d', v.get('name')
        end
      end
    end
  end

  def test_spider_can_keep_eyes_on_next_page
    @spider.entrance('/page/1')
    @spider.learn do
      keep_eyes_on_next_page('.pages a.next_page')
      field(:current_page, '#current_page')
    end
    excretion = @spider.crawl
    excretion.each do |k,v|
      k =~ /\/page\/(\d)/
      assert_equal "Current Page #{$1}", v.get('current_page')
    end
  end

  def test_spider_can_follow_and_keep_eyes_on_next_page
    @spider.entrance('/page/1')
    @spider.follow('a.next_page') do
      keep_eyes_on_next_page('.pages a.next_page')
      field :current_page, '#current_page'
    end
    excretion = @spider.crawl
    excretion['/page/1']['follow::a.next_page'].each do |k, v|
      k =~ /\/page\/(\d)/
      assert_equal "Current Page #{$1}", v.get('current_page')
    end
  end

  def test_spider_can_nest_follow_lots_of_links_and_keep_eyes_on_next_page
  end

  def test_spider_can_create_custom_action
    @saved = false
    @spider.create_action(:save) do |result|
      @saved = true
    end
    @spider.learn do
      entrance '/'
      field :name, '#name'
      save
    end
    excretion = @spider.crawl
    assert_equal true, @saved
    assert_equal 'Home', excretion['/']['name']
    assert_equal 'Home', @spider.get('name')
  end

  #def test_spider_can_create_custom_action_reached_by_spawn
    #@saved = false
    #@spider.create_action(:save) do |result|
      #@saved = true
    #end
    #@spider.learn do
      #entrance '/'
      #field :name, '#name'
      #save
      #follow '.links a' do
        #field :name, '#name'
        #save
      #end
    #end
    #excretion = @spider.crawl
    #require 'pry'; binding.pry
    #assert_equal true, @saved
  #end
end
