# create and use new rvm gemset
# rvm_lib_path = ENV["rvm_lib_path"]
# rvm_ruby_string = ENV["rvm_ruby_string"]
# $LOAD_PATH.unshift(rvm_lib_path) unless $LOAD_PATH.include?(rvm_lib_path)
# require 'rvm'
# rvm_env = RVM::Environment.new rvm_ruby_string
# puts "Creating gemset #{rvm_ruby_string}@#{app_name}"
# rvm_env.gemset_create(app_name)
# puts "Now using gemset #{app_name}"
# rvm_env.gemset_use!(app_name)

# puts "Installing bundler gem."
# puts "Successfully installed bundler" if rvm_env.system("gem", "install", "bundler")
# puts "Installing rails gem."
# puts "Successfully installed rails" if rvm_env.system("gem", "install", "rails")
rvm_ruby_string = ENV["rvm_ruby_string"]
create_file ".rvmrc", "rvm use #{rvm_ruby_string}@#{app_name} --create"

# install gems
run "rm Gemfile"
create_file "Gemfile", <<-EOS
source 'http://rubygems.org'

gem 'rails', '3.0.5'
gem 'mysql2'
gem 'compass'
gem 'haml-rails'
gem 'devise'

group :development, :test do
  gem 'rspec-rails'
  gem 'cucumber-rails'
  gem 'pickle'
  gem 'capybara'
  gem 'factory_girl_rails'
end

# hpricot and ruby_parser required by haml
group :development do
  gem "hpricot"
  gem "ruby_parser"
end
EOS

# bundle install
run "bundle install"

# convert layout to haml
run "html2haml app/views/layouts/application.html.erb app/views/layouts/application.html.haml"
run "rm app/views/layouts/application.html.erb"

# # customize generators
# inject_into_file 'config/application.rb', :after => "config.filter_parameters += [:password]" do
#   <<-eos
# 
#     # Customize generators
#     config.generators do |g|
#       g.stylesheets false
#       g.fixture_replacement :factory_girl, :dir => 'spec/factories'
#     end
#   eos
# end

# generate rspec, cucumber, and pickle
generate "rspec:install"
generate "cucumber:install --capybara --rspec"
generate "pickle --paths --email --force"

# # install jquery
# generate "jquery:install"

# alternative to jquery-rails generator
run "curl -L http://code.jquery.com/jquery.min.js > public/javascripts/jquery.js"
run "curl -L http://github.com/rails/jquery-ujs/raw/master/src/rails.js > public/javascripts/rails.js"

gsub_file 'config/application.rb', /(config.action_view.javascript_expansions.*)/, 
                                  "config.action_view.javascript_expansions[:defaults] = %w(jquery rails)"

# remove active_resource and test_unit
gsub_file 'config/application.rb', /require 'rails\/all'/, <<-CODE
  require 'rails'
  require 'active_record/railtie'
  require 'action_controller/railtie'
  require 'action_mailer/railtie'
CODE

rake "db:drop"
rake "db:create", :env => "development"
rake "db:migrate"

# add time format
environment '  Time::DATE_FORMATS.merge!(:default => "%Y/%m/%d %I:%M %p", :ymd => "%Y/%m/%d")'

# .gitignore
append_file '.gitignore', <<-EOS
config/database.yml
Thumbs.db
.DS_Store
tmp/*
coverage
*.swp
EOS

# git commit
git :init
git :add => '.'
git :commit => "-a -m 'initial commit'"

# Devise setup
generate "devise:install"
generate "devise User"
# generate "devise:views -e erb"
rake "db:migrate"

generate "controller home index"

# add root :to => "" to routes
inject_into_file 'config/routes.rb', :after => "#{app_const}.routes.draw do" do
  <<-EOS

  root :to => "home#index"
  EOS
end

# TODO
# config email for devise
# add flash messages to layout?

# compass and yui here
run "compass init rails ."

gsub_file 'app/views/layouts/application.html.haml', /\s*(= stylesheet_link_tag :all)\n/, <<-EOS

    = stylesheet_link_tag 'compiled/screen.css', :media => 'screen, projection'
    = stylesheet_link_tag 'compiled/print.css', :media => 'print'
    /[if IE]
      = stylesheet_link_tag 'compiled/ie.css', :media => 'screen, projection'
EOS

# remove unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/images/rails.png"
run "cp config/database.yml config/database.yml.example"


# add YUI3 stylesheets
run "curl -L http://yui.yahooapis.com/3.3.0/build/cssreset/reset-min.css > app/stylesheets/_yui_reset.scss"
run "curl -L http://yui.yahooapis.com/3.3.0/build/cssfonts/fonts-min.css > app/stylesheets/_yui_fonts.scss"
run "curl -L http://yui.yahooapis.com/3.3.0/build/cssgrids/grids-min.css > app/stylesheets/_yui_grids.scss"
create_file "app/stylesheets/_layout.scss"

gsub_file 'app/stylesheets/screen.scss', /@import "compass\/reset"/, <<-EOS
@import "yui_reset";
@import "yui_fonts";
@import "yui_grids";
@import "layout";
EOS

say <<-eos
  ============================================================================
  Your new Rails application is ready to go.
  
  Don't forget to scroll up for important messages from installed generators.
eos
