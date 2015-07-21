DesksnearMe::Application.configure do
  config.use_only_ssl = false
  config.cache_classes = false

  config.eager_load = false

  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.reload_classes_only_on_change = true

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  Rails.application.routes.default_url_options[:host] = 'localhost:3000'
  Rails.application.routes.default_url_options[:protocol] = 'http'

  config.active_support.deprecation = :log

  config.action_dispatch.best_standards_support = :builtin

  config.assets.digest = false
  config.assets.debug = false
  config.assets.raise_runtime_errors = false

  config.exceptions_app = nil

  # Don't perform mixpanel and google analytics requests for development
  config.perform_mixpanel_requests = false
  config.perform_google_analytics_requests = false
  config.perform_social_jobs = false

  config.encrypt_sensitive_db_columns = false
  config.silence_raygun_notification = true
  config.assets.enforce_precompile = true

  config.root_secured = false
  config.secure_app = false
  config.run_jobs_in_background = false
  config.googl_api_key = 'AIzaSyBV7BhIuT6s2HbprOP4jfXSmpdBFmocSMg'
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025 }

  config.middleware.insert_after(ActionDispatch::Static, SilentMissedImages)
end
