require 'hashie'
require 'capybara'
require 'capybara/dsl'
require 'capybara/mechanize'

Capybara.default_driver = :mechanize
Capybara.current_driver = :mechanize
Capybara.app = proc { |env| [200, {'Content-Type' => 'text/html'}, 'You need to use MicroSpider#site method to set app host.'] }
Capybara.configure do |config|
  config.ignore_hidden_elements = false
  config.run_server = false
end

# If has capybara-webkit, first priority
begin
  require 'capybara-webkit'
  Capybara.current_driver = :webkit
rescue Exception => e
  # Nothing to do.
end

require 'logger'
require 'set'
require 'timeout'
require 'spider_core'

class MicroSpider

  include Capybara::DSL
  include SpiderCore::Behavior
  include SpiderCore::FieldDSL
  include SpiderCore::FollowDSL
  include SpiderCore::PaginationDSL

  attr_reader   :excretion, :paths, :delay, :current_location, :visited_paths, :broken_paths
  attr_accessor :logger, :actions, :recipe, :skip_set_entrance, :timeout, :selector

  def initialize(excretion = nil, selector: :css)
    @selector         = selector
    @paths            = []
    @actions          = []
    @setted_variables = {}
    @timeout          = 120
    @status           = 'pending'
    @excretion        = excretion || SpiderCore::Excretion.new
    @logger           = Logger.new(STDOUT)
    @visited_paths    = Set.new
    @broken_paths     = []
  end

  # The seconds between each two request.
  #
  # @param sec [Float]
  def delay=(sec)
    raise ArgumentError, 'Delay sec can not be a negative number.' if sec.to_f < 0
    @delay = sec.to_f
  end

  # Visit the path.
  #
  # @param path [String] the path to visit, can be absolute path or relative path.
  #
  # @example Visit a path
  #   spider = MicroSpider.new
  #   spider.visit('/example')
  #   spider.visit('http://google.com')
  #
  def visit(path)
    raise ArgumentError, "Path can't be nil or empty" if path.nil? || path.empty?
    sleep_or_not
    logger.info "Begin to visit #{path}."
    super(path)
    @current_location = SpiderCore::Excretion['_path' => path]
    logger.info "Current location is #{path}."
  end

  # Set a variable. You can use it later.
  #
  # @param name [String]  the variable name
  # @param value [String] the variable value
  # @param opts [Hash] the options. can set selector with css or xpath
  #
  # @example Set a variable
  #   spider = MicroSpider.new
  #   spider.set :id, '645'
  #   spider.set :table, '.tb a', selector: :css
  #   spider.set :table, '.tb a', selector: :css do |e|
  #     e['src']
  #   end
  def set(name, value)
    @setted_variables[name.to_s] = value
  end

  def set_on(name, pattern, &block)
    actions << lambda {
      element = scan_first(pattern)
      @setted_variables[name.to_s] = block_given? ? yield(element) : handle_element(element)
    }
  end

  # Click the locator. This will trigger visit action and change current location.
  # @params locator [String] the text or id of the link.
  #
  def click(locator, opts = {}, &block)
    actions << lambda {
      path = find_link(locator, opts)[:href] rescue nil
      raise SpiderCore::ClickPathNotFound, "#{locator} not found" if path.nil?
      if block_given?
        spider = self.spawn
        spider.entrance(path)
        spider.learn(&block)
        put(
          "click::#{path}", spider.crawl
        )
      else
        visit(path)
      end
    }
  end

  # Teach the spider behaviors and it will repeat to the end.
  # @param recipe [String, Proc] the recipe be learned.
  #
  # @example
  #   spider = MicroSpider.new
  #   spider.learn do
  #     entrance 'http://google.com'
  #   end
  #   spider.crawl
  #
  # @example
  #   spider.learn("entrance 'http://google.com'")
  #   spider.crawl
  #
  # @example
  #   recipe = lambda {
  #     entrance 'http://google.com'
  #   }
  #   spider.learn(recipe)
  #   spider.crawl
  #
  def learn(recipe = nil, &block)
    if block_given?
      instance_eval(&block)
      @recipe = block
    elsif recipe.is_a?(Proc)
      instance_eval(&recipe)
      @recipe = recipe
    elsif recipe.is_a?(String)
      instance_eval(recipe)
      @recipe = recipe
    else
      self
    end
  end

  def site(url)
    return if @site
    Capybara.app_host = @site = url
  end

  # This will be the first path for spider to visit.
  # If more than one entrance, the spider will crawl theme one by one.
  # @param path_or_paths [String] one or more entrances
  #
  # @example
  #   spider = MicroSpider.new
  #   spider.site('http://google.com')
  #   spider.entrance('/a')
  #   spider.entrance('/b')
  #
  def entrance(*path_or_paths)
    return if @skip_set_entrance
    @paths += path_or_paths
  end

  def with(pattern, path:, &block)
    visit(path)
    scan_all(pattern).map{ |element| yield(element) }
  end

  # Sometimes the entrances are on the page.
  # @param path [String] path to visit
  # @param pattern [String, Regexp] links pattern
  #
  # @example
  #   spider = MicroSpider.new
  #   spider.entrance_on('.links a')
  #   spider.entrance_on('.links a', path: '/a')
  #
  def entrance_on(pattern, path: '/', attr: :href)
    return if @skip_set_entrance

    visit(path)
    entrances = scan_all(pattern).map{ |element| element[attr] }
    @paths += entrances.to_a
  end

  def crawl(&block)
    return excretion if completed?

    @paths.compact!
    path = nil
    loop do
      path = @paths.shift
      break if path.nil?
      break unless @visited_paths.include?(path)
    end

    if path.nil?
      complete
      return excretion
    end

    learn(@recipe) if @actions.empty?

    begin
      visit(path)
      @status = 'inprogress'
    rescue Timeout::Error => err
      @broken_paths << path
      logger.fatal("Timeout!!! execution expired when visit `#{path}`")
      logger.fatal(err)
    rescue SystemExit, Interrupt
      logger.fatal("SystemExit && Interrupt")
      @status = 'exit'
      exit!
    rescue Exception => err
      @broken_paths << path
      logger.fatal("Caught exception when visit `#{path}`")
      logger.fatal(err)
      logger.fatal(err.backtrace.join("\n"))
    else
      @visited_paths << path
      execute_actions
      @excretion = @excretion.put(path, @current_location)
      #@excretion[path] = @current_location
      #yield(@current_location) if block_given?
      #excretion[:results] << @current_location
    ensure
      @actions = []
      @skip_set_entrance = true
      crawl(&block)
    end

    excretion
  end

  def reset
    return unless completed?
    @paths            = visited_paths.to_a
    @status           = 'pending'
    @excretion        = nil
    @visited_paths    = Set.new
    @current_location = nil
  end

  # Spider can create custom action when it is crawling.
  # @param name [String] the name of action
  # @param block [Proc] the actions
  #
  # @example
  #   spider = MicroSpider.new
  #
  #   spider.create_action :save do |result|
  #     SomeClass.save(result)
  #   end
  #
  #   spider.save
  #
  def create_action(name, &block)
    action = proc { actions << lambda { block.call(@excretion) } }
    metaclass.send :define_method, name, &action
  end

  def execute_actions
    actions.delete_if { |action|
      begin
        Timeout::timeout(@timeout) { action.call }
      rescue Timeout::Error => err
        logger.fatal('Timeout!!! execution expired when execute action')
        logger.fatal(err.message)
        logger.fatal(err.backtrace.inspect)
        @visited_paths.pop
        break
      rescue SpiderCore::ClickPathNotFound => err
        logger.fatal(err.message)
        logger.fatal(err.backtrace.inspect)
        @visited_paths.pop
        break
      end
    }
  end

  # @example
  #   spider = MicroSpider.new
  #   kid = spider.spawn
  #
  #   or
  #
  #   kid = spider.spawn do
  #     ...
  #     ...
  #   end
  def spawn(&block)
    spider         = self.class.new
    spider.logger  = logger
    spider.timeout = timeout
    spider.site(@site)
    spider.learn(&block) if block_given?
    spider
  end

  def completed?
    @status == 'completed'
  end

  def metaclass
    class << self; self; end
  end

  def get(field)
    @_deep_fetch ||= excretion.extend Hashie::Extensions::DeepFind
    result = @_deep_fetch.deep_find_all(field.to_s)
    return if result.nil?
    result.length == 1 ? result.pop : result
  end

  # The default page is Capybara.current_session.
  # Share one page may cause difficult issue, so here i separate it.
  def page
    @page ||= Capybara::Session.new(Capybara.mode, Capybara.app)
  end

  # Because we don't share the page, the connect may or maynot be killd, it will eat too much mem.
  # Make this spider instance suicide.
  # For now, specially for `capybara-webkit`
  def suicide
    if Capybara.mode.to_s == 'webkit'
      @page.driver.browser.instance_variable_get(:@connection).send :kill_process
    end
    @page = nil
  end

  protected

    def sleep_or_not
      if delay && delay > 0
        logger.info "Nedd sleep #{delay} sec."
        sleep(delay)
        logger.info 'Wakeup'
      end
    end

    def complete
      @status = 'completed'
      suicide
    end

end
