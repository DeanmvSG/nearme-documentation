source 'http://rubygems.org'

gem 'rails', '3.0.3'
gem 'pg'
gem 'devise'
gem 'omniauth'
gem 'rails-geocoder', :require => 'geocoder'
gem 'capistrano'
gem 'simple_form'
gem 'mini_magick'
gem 'carrierwave'
gem 'state_machine'
gem 'jquery-rails'
gem "RedCloth", "~> 4.2.9", :require => "redcloth"
gem 'fog'
gem 'gravtastic'
gem 'will_paginate'
gem 'tweet-button'
gem 'haml'
gem 'thinking-sphinx', :git => 'git://github.com/freelancing-god/thinking-sphinx.git',
                       :branch => 'rails3',
                       :require => 'thinking_sphinx'

group :development do
  gem 'capushka', :require => false
end

group :development, :test do
  gem 'ffaker'
  gem 'ruby-debug19', :require => "ruby-debug"
  gem 'rspec', '>= 2.0.0'
  gem 'rspec-rails', '>= 2.0.0'
end

group :test do
  gem 'webmock', :git => 'git://github.com/bblimke/webmock'
  gem 'timecop'
  gem 'autotest'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'cucumber-rails'
  gem 'pickle'
  gem 'factory_girl_rails'
  gem 'launchy'
end

group :production do
  gem 'exception_notification', :git => "git://github.com/rails/exception_notification", :require => 'exception_notifier'
end

group :development, :production do
  gem 'newrelic_rpm'
end
