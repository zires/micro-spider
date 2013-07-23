require 'capybara'
require 'capybara-webkit'
require 'capybara/dsl'

Capybara.run_server = false
Capybara.current_driver = :webkit

require 'logger'
require 'spider_core'

class MicroSpider

  include Capybara::DSL
  include SpiderCore::Behavior
  include SpiderCore::FieldDSL
  include SpiderCore::FollowDSL
  include SpiderCore::PaginationDSL

  attr_reader   :excretion, :paths, :delay, :current_location
  attr_accessor :logger, :actions, :recipe, :skip_set_entrance

  def initialize(excretion = nil)
    @paths     = []
    @actions   = []
    @excretion = excretion || { status: 'inprogress', results: [] }
    @logger    = Logger.new(STDOUT)
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
  # @example Visit a path
  #   spider = TinySpider.new
  #   spider.visit('/example')
  #   spider.visit('http://google.com')
  #
  def visit(path)
    sleep_or_not
    logger.info "Begin to visit #{path}."
    super(path)
    @current_location = {entrance: path}
    logger.info "Current location is #{path}."
  end

  def click(locator, opts = {})
    actions << lambda { 
      path = find_link(locator, opts)[:href]
      visit(path)
    }
  end

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
    Capybara.app_host = @excretion[:site] = @site = url
  end

  def entrance(*path_or_paths)
    return if @skip_set_entrance
    @paths += path_or_paths
  end

  def entrance_on_path(path, pattern, kind: :css, **opts, &block)
    return if @skip_set_entrance
    visit(path)
    entrances = scan_all(kind, pattern, opts).map do |element|
      block_given? ? yield(element) : element[:href]
    end
    @paths += entrances.to_a
  end

  def crawl(&block)
    return excretion if completed?

    @paths.compact!
    path = @paths.shift
    if path.nil?
      excretion[:status] = 'completed'
      return excretion
    end

    visit(path)
    execute_actions
    yield(@current_location) if block_given?
    excretion[:results] << @current_location

    @skip_set_entrance = true
    learn(@recipe)
    crawl(&block)

    excretion
  end

  def create_action(name, &block)
    action = proc { actions << lambda { block.call(current_location) } }
    metaclass.send :define_method, name, &action
  end

  def execute_actions
    actions.delete_if { |action| action.call }
  end

  def spawn
    spider = self.clone
    spider.instance_variable_set(:@paths, [])
    spider.instance_variable_set(:@actions, [])
    spider.instance_variable_set(:@excretion, { status: 'inprogress', results: [] })
    spider.skip_set_entrance = false
    spider
  end

  def results
    excretion[:results]
  end

  def completed?
    excretion[:status] == 'completed'
  end

  def metaclass
    class << self; self; end
  end

  protected
  def sleep_or_not
    if delay && delay > 0
      logger.info "Nedd sleep #{delay} sec."
      sleep(delay)
      logger.info 'Wakeup'
    end
  end

end
