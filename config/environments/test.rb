DesksnearMe::Application.configure do
  Rails.application.routes.default_url_options[:host] = "example.com"
  config.action_controller.allow_forgery_protection    = false
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = true
  config.action_mailer.delivery_method = :test
  config.active_record.mass_assignment_sanitizer = :strict
  config.active_support.deprecation = :stderr
  config.cache_classes = true
  config.consider_all_requests_local       = true
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"
  config.whiny_nils = true

  config.perform_social_jobs = false
  config.after_initialize do
      PaperTrail.enabled = false
  end
  config.encrypt_sensitive_db_columns = false
  config.silence_raygun_notification = true
end
