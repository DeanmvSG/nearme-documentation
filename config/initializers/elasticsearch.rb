config = {
  host: "http://localhost:9200/",
  transport_options: {
    request: { timeout: 5 }
  }
}

if File.exists?("config/elasticsearch.yml")
  elastic_config = YAML.load_file("config/elasticsearch.yml").symbolize_keys
  config.merge!(elastic_config[Rails.env.to_sym])
end

Elasticsearch::Model.client = Elasticsearch::Client.new(config)