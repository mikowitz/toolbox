git :init
git add: '.'
git commit: '-am "first commit"'

run 'rm -rf test'

options = {}

def ask_with_default(prompt, default)
  value = ask("#{prompt} [#{default}]")
  value.blank? ? default : value
end

if yes?('Do you want to use Devise?')
  options[:devise_model] = ask_with_default('What should the user model be called?', 'User').classify

  say "We can seed the database with a starting #{options[:devise_model]}", :yellow
  options[:user_email] = ask_with_default 'Email', `git config --get user.email`.chomp
  options[:user_password] = ask_with_default 'Password', 'password'
end

gem 'kaminari'
gem 'haml'
gem 'pg'
gem 'simple_form'
gem 'devise' if options[:devise_model]

gem_group :development do
  gem 'debugger'
  gem 'quiet_assets'
  gem 'haml-rails'
end

gem_group :assets do
  gem 'sass-rails', :version => '~> 3.2.3'
  gem 'coffee-rails', :version => '~> 3.2.1'
  
  gem 'bootstrap-sass'
end

gem_group :development, :test do
  gem 'rspec-rails'
end

gem_group :test do
  gem 'factory_girl_rails'
  gem 'turnip'
  gem 'capybara'
  gem 'ffaker'
  gem 'shoulda-matchers'
  gem 'valid_attribute'
end

run 'bundle install'

application <<-GENERATORS
config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_girl
    end
GENERATORS

application 'config.assets.initialize_on_precompfile = false'

generate 'rspec:install'
generate 'simple_form:install', '--bootstrap'

create_file 'spec/support/factory_girl.rb', <<-SUPPORT
Rspec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  #{"config.include Devise::TestHelpers, :type => :controller" if options[:devise_model]}
end
SUPPORT

gsub_file 'config/database.yml', /username:.*$/, 'username: postgres'
rake 'db:create'

if options[:devise_model]
  generate 'devise:install'
  generate 'devise', options[:devise_model]
  generate 'devise:views'
  
  append_to_file 'db/seeds.rb', <<-SEED
#{options[:devise_model]}.create!(
  :email => %q{#{options[:user_email]}},
  :password => %q{#{options[:user_password]}}) unless #{options[:devise_model]}.any?
SEED

  create_file "spec/factories/#{options[:devise_model].underscore}s.rb", <<-FACTORY
FactoryGirl.define do
  factory :#{options[:devise_model].underscore} do
    email     { Faker::Internet.disposable_email }
    password  'password'
  end
end
FACTORY
end

append_to_file 'app/assets/javascripts/application.js', <<-JS
//=require bootstrap
JS

create_file 'app/assets/stylesheets/screen.css.sass', <<-SASS
@import 'bootstrap'
@import 'bootstrap/responsive'
SASS

gsub_file 'app/assets/stylesheets/application.css', /require_tree \.$/, 'require screen'

git add: '.'
git commit: '-am "customizr"'
