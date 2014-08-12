require File.expand_path('../boot', __FILE__)

require 'rails/all'

groups = {}
groups[:coverage]  =  [Rails.env.to_s] if ENV['COVERAGE']
groups[:profiling] =  [Rails.env.to_s] if ENV['PERF']

Bundler.require(*Rails.groups(groups)) if defined?(Bundler)

module DesksnearMe
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths -= Dir["#{config.root}/lib/previewers/"] unless defined? MailView

    config.to_prepare do
      # Load application's view overrides
      Dir.glob(File.join(File.dirname(__FILE__), "../app/overrides/*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load Spree model's decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/models/spree/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      # Load Spree controllers's decorators
      Dir.glob(File.join(File.dirname(__FILE__), "../app/controllers/spree/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    config.assets.paths           << %(#{Rails.root}/app/assets/fonts)
    config.assets.paths           << %(#{Rails.root}/app/assets/swfs)
    config.assets.paths           << %(#{Rails.root}/app/assets/videos)

    config.assets.precompile +=  ['*.js']

    config.assets.precompile += [
      "vendor/jquery.backgroundSize.min.js","vendor/respond.proxy.js", "vendor/respond.min.js",
      "admin.js", "blog.js", "blog_admin.js", "chrome_frame.js", "instance_admin.js",
      "platform_home.js", "analytics/sessioncam.js", "blog/admin/*"
    ]
    config.assets.precompile += [
      "browser_specific/ie8.css", "admin.css", "blog.css", "blog_admin.css", "errors.css",
      "instance_admin.css", "platform_home.css"
    ]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [
      :password, :bank_routing_number, :bank_account_number, :response,
      :marketplace_password, :olark_api_key, :facebook_consumer_key, :facebook_consumer_secret, :twitter_consumer_key,
      :twitter_consumer_secret, :linkedin_consumer_key, :linkedin_consumer_secret, :instagram_consumer_key, :instagram_consumer_secret,
      :stripe_id, :paypal_id, :balanced_user_id, :balanced_credit_card_id, :live_settings, :test_settings
    ]

    config.generators do |g|
      g.test_framework :test_unit, :fixture => false
    end
    config.use_only_ssl = true

    # note that we *don't* want to rewite for the test env :)
    config.should_rewrite_email = Rails.env.staging? || Rails.env.development?
    config.test_email           = ENV['DNM_TEST_EMAIL'] || "notifications@desksnear.me"

    config.action_mailer.default_url_options = { :host => 'desksnear.me' }

    # Access the DB or load models when precompiling assets
    config.assets.initialize_on_precompile = true

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.digest = true

    # Clould services credentials
    CarrierWave.configure do |config|
      config.fog_attributes = {'Cache-Control'=>'max-age=315576000, public'}
      config.storage        = :file
    end

    # Development/Test specific keys/secrets for social properties.
    config.linkedin_key = "4q9xfgn60bik"
    config.linkedin_secret = "lRmKVrc0RPpfKDCV"

    config.facebook_key = "432038396866156"
    config.facebook_secret = "71af86082de1c38a3523a4c8f44aca2d"

    config.twitter_key = "Xas2mKTWPVpqrb5FXUnDg"
    config.twitter_secret = "nR8pjJ9YcU3eK9pKUPFBNxZuJ5oMci2M96SpZ47Ik"

    config.instagram_key = "566499e0d6e647518d8f4cec0a42f3d6"
    config.instagram_secret = "5c0652ad06984bf09e4987c8fc5ea8f1"

    config.exceptions_app = self.routes

    # custom rewrites specified in lib/legacy_redirect_handler.rb
    config.middleware.insert_before(Rack::Sendfile, "LegacyRedirectHandler")
    # setting platform_context in app/models/platform_context/rack_setter.rb
    config.middleware.use "PlatformContext::RackSetter"
    config.mixpanel = (YAML.load_file(Rails.root.join("config", "mixpanel.yml"))[Rails.env] || {}).with_indifferent_access
    config.google_analytics = (YAML.load_file(Rails.root.join("config", "google_analytics.yml"))[Rails.env] || {}).with_indifferent_access
    config.near_me_analytics = (YAML.load_file(Rails.root.join("config", "near_me_analytics.yml"))[Rails.env] || {}).with_indifferent_access
    config.filepicker_rails.api_key = YAML.load_file(Rails.root.join("config", "inkfilepicker.yml"))[Rails.env]["api_key"]

    config.perform_mixpanel_requests = true
    config.perform_google_analytics_requests = true
    config.perform_social_jobs = true

    config.action_dispatch.rescue_responses.merge!('Page::NotFound' => :not_found)
    config.action_dispatch.rescue_responses.merge!('Listing::NotFound' => :not_found)
    config.action_dispatch.rescue_responses.merge!('Location::NotFound' => :not_found)

    config.paypal_mode = 'sandbox'
    config.encrypt_sensitive_db_columns = true

    config.silence_raygun_notification = false

    config.paypal_email = nil
    config.paypal_username = nil
    config.paypal_password = nil
    config.paypal_signature = nil
    config.paypal_client_id = nil
    config.paypal_client_secret = nil
    config.paypal_app_id = nil

    config.stripe_api_key = nil
    config.stripe_public_key = nil

    config.balanced_api_key = nil

    config.secure_app = true
    config.root_secured = true

  end
end
