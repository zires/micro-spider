begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'sinatra/base'
require 'test/unit'
require 'pry'

# Enable turn if it is available
begin
  require 'turn'
rescue LoadError
end

require 'tiny_spider'

class MyApp < Sinatra::Base

  get '/' do
    erb <<-ERB
<div id="name">Home</div>
<div class='links'>
  <a href='/a'>A</a>
  <a href='/b'>B</a>
  <a href='/c'>C</a>
  <a href='/d'>D</a>
</div>
    ERB
  end
  
  get '/a' do
    erb <<-ERB
<div id='name'>This is a</div>
<div class='links'>
  <a href='/a'>A</a>
  <a href='/b'>B</a>
  <a href='/c'>C</a>
  <a href='/d'>D</a>
</div>
    ERB
  end

  get '/b' do
    erb <<-ERB
<div id='name'>This is b</div>
<div class='links'>
  <a href='/a'>A</a>
  <a href='/b'>B</a>
  <a href='/c'>C</a>
  <a href='/d'>D</a>
</div>
    ERB
  end


  get '/c' do
    erb <<-ERB
<div id='name'>This is c</div>
<div class='links'>
  <a href='/a'>A</a>
  <a href='/b'>B</a>
  <a href='/c'>C</a>
  <a href='/d'>D</a>
</div>
    ERB
  end


  get '/d' do
    erb <<-ERB
<div id='name'>This is d</div>
<div class='links'>
  <a href='/a'>A</a>
  <a href='/b'>B</a>
  <a href='/c'>C</a>
  <a href='/d'>D</a>
</div>
    ERB
  end

  get '/page/:page' do
    @current_page = params[:page]
    erb <<-ERB
<div id='current_page'>Current Page <%= @current_page %></div>
<div class='pages'>
  <% next_page = @current_page.to_i < 3 ? @current_page.to_i + 1 : nil %>
  <% if next_page %>
  <a href='/page/<%= next_page %>' class='next_page'>next page</a>
  <% end %>
</div>
    ERB
  end


end

Capybara.use_default_driver
Capybara.app = MyApp

