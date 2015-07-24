require 'message_bus'
DesksnearMe::Application.configure do
  config.eager_load = true

  config.cache_classes = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.action_dispatch.x_sendfile_header = "X-Sendfile"
  config.serve_static_assets = false
  config.static_cache_control = "public, max-age=7200"

  config.action_mailer.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :enable_starttls_auto => true,
    :user_name      => "admin@desksnear.me",
    :password       => "K6c#H3UWi}%DD6vUT$9W",
    :domain         => 'desksnear.me'
  }

  Rails.application.routes.default_url_options[:host] = 'desksnear.me'
  Rails.application.routes.default_url_options[:protocol] = 'https'

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify

  config.assets.compile = false
  config.assets.manifest = "#{Rails.root}/config/manifest.json"

  # Clould services credentials
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider                   => 'AWS',
      :aws_access_key_id          => 'AKIAI5EVP6HB47OZZXXA',
      :aws_secret_access_key      => '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',
      :path_style                 => true
    }
    config.fog_directory        = 'near-me.production'
    config.asset_host           = 'https://production-uploads-nearme.netdna-ssl.com'
    config.storage              = :fog
  end

  config.action_controller.asset_host = "//production-nearme.netdna-ssl.com"
  config.action_mailer.asset_host     = "https://production-nearme.netdna-ssl.com"

  config.paypal_mode = 'live'
  config.redis_settings = YAML.load_file(Rails.root.join("config", "redis.yml"))[Rails.env.to_s]
  config.message_bus_handler = MessageBus
  config.cache_store = :redis_store, {
    :host => config.redis_settings["host"],
    :port => config.redis_settings["port"].to_i,
    :namespace => "cache"
  }
  config.send_real_sms = true

  # for ELB management
  AWS.config(access_key_id: 'AKIAJYA2ZJ5BQTU5QBMA',
             secret_access_key: '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',
             region: 'us-west-1')

  # Google link shortening service
  config.googl_api_key = 'AIzaSyDQfdHdnh0u-0yRhqmSZchhkpFVIgXy2Jc'
end
