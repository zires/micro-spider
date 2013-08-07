require 'test_helper'

class MicroSpiderTest < MiniTest::Unit::TestCase

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

  def test_spider_can_follow_lots_of_links
    @spider.entrance('/')
    @spider.follow('.links a') do
      field :name, '#name'
    end
    excretion = @spider.crawl
    excretion[:results].first[:follow].first.each do |f|
      case f[:entrance]
      when '/a'
        assert_equal 'This is a', f[:field].first[:name]
      when '/b'
        assert_equal 'This is b', f[:field].first[:name]
      when '/c'
        assert_equal 'This is c', f[:field].first[:name]
      when '/d'
        assert_equal 'This is d', f[:field].first[:name]
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
    excretion[:results].first[:follow].first.each do |f|
      refute_empty f[:follow].first
      f[:follow].first.each do |ff|
        case ff[:entrance]
        when '/a'
          assert_equal 'This is a', ff[:field].first[:name]
        when '/b'
          assert_equal 'This is b', ff[:field].first[:name]
        when '/c'
          assert_equal 'This is c', ff[:field].first[:name]
        when '/d'
          assert_equal 'This is d', ff[:field].first[:name]
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
    excretion[:results].each do |f|
      f[:entrance] =~ /\/page\/(\d)/
      assert_equal "Current Page #{$1}", f[:field].first[:current_page]
    end
  end
  
  def test_spider_can_follow_and_keep_eyes_on_next_page
    @spider.entrance('/page/1')
    @spider.follow('a.next_page') do
      keep_eyes_on_next_page('.pages a.next_page')
      field :current_page, '#current_page'
    end
    excretion = @spider.crawl
    excretion[:results].first[:follow].first.each do |f|
      f[:entrance] =~ /\/page\/(\d)/
      assert_equal "Current Page #{$1}", f[:field].first[:current_page]
    end
  end

  def test_spider_can_nest_follow_lots_of_links_and_keep_eyes_on_next_page
  end

  def test_spider_can_create_custom_action
    @spider.create_action(:save) do |result|
      result[:save] = 'saved'
    end
    @spider.learn do
      entrance '/'
      field :name, '#name'
      save
    end
    excretion = @spider.crawl
    assert_equal 'saved', excretion[:results].first[:save]
  end

  def test_spider_can_create_custom_action_reached_by_spawn
    @spider.create_action(:save) do |result|
      result[:save] = 'saved'
    end
    @spider.learn do
      entrance '/'
      field :name, '#name'
      save
      follow '.links a' do
        field :name, '#name'
        save
      end
    end
    excretion = @spider.crawl
    assert_equal 'saved', excretion[:results].first[:follow].first[0][:save]
  end

end
