# remove unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/images/rails.png"
run "cp config/database.yml config/database.yml.example"

# create new rvm gemset and .rvmrc
run "rvm gemset create #{app_name}"
run "rvm gemset use #{app_name}"
create_file ".rvmrc", "rvm use 1.9.2@#{app_name} --create"

# install gems
run "rm Gemfile"
create_file "Gemfile", <<-EOS
source 'http://rubygems.org'

gem 'rails', '3.0.5'
gem 'mysql2'

gem 'compass'
gem 'haml-rails'
gem 'jquery-rails'

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

# install jquery
generate "jquery:install"

# # alternative to jquery-rails generator
# run "curl -L http://code.jquery.com/jquery.min.js > public/javascripts/jquery.js"
# run "curl -L http://github.com/rails/jquery-ujs/raw/master/src/rails.js > public/javascripts/rails.js"

# gsub_file 'config/application.rb', /(config.action_view.javascript_expansions.*)/, 
#                                   "config.action_view.javascript_expansions[:defaults] = %w(jquery rails)"

# remove active_resource and test_unit
gsub_file 'config/application.rb', /require 'rails\/all'/, <<-CODE
  require 'rails'
  require 'active_record/railtie'
  require 'action_controller/railtie'
  require 'action_mailer/railtie'
CODE

rake "db:drop"
rake "db:create", :env => "development"
rake "db:create", :env => "test"
rake "db:migrate"

# add time format
environment 'Time::DATE_FORMATS.merge!(:default => "%Y/%m/%d %I:%M %p", :ymd => "%Y/%m/%d")'

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
generate "devise:views"
rake "db:migrate"

# add root :to => "home#index" to routes
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

# gsub_file 'app/views/layout/application.html.haml', /\s*(= stylesheet_link_tag :all)\n/, ""

gsub_file 'app/views/layout/application.html.haml', /\s*(= stylesheet_link_tag :all)\n/, <<-EOS

    = stylesheet_link_tag 'compiled/screen.css', :media => 'screen, projection'
    = stylesheet_link_tag 'compiled/print.css', :media => 'print'
    /[if IE]
      = stylesheet_link_tag 'compiled/ie.css', :media => 'screen, projection'
EOS

# inject_into_file 'app/views/layout/application.html.haml', :after => "%title #{app_const_base}" do
#   <<-EOS
# 
#     = stylesheet_link_tag 'compiled/screen.css', :media => 'screen, projection'
#     = stylesheet_link_tag 'compiled/print.css', :media => 'print'
#     /[if IE]
#       = stylesheet_link_tag 'compiled/ie.css', :media => 'screen, projection'
#   EOS
# end

say <<-eos
  ============================================================================
  Your new Rails application is ready to go.
  
  Don't forget to scroll up for important messages from installed generators.
eos
