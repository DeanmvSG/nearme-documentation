class Authentication::FacebookProvider < Authentication::BaseProvider

  META   = { name: "Facebook",
             url: "http://facebook.com/",
             auth: "OAuth 2" }


  def self.setup_proc 
    lambda do |env| 
      env['omniauth.strategy'].options[:client_id] = PlatformContext.current.instance.facebook_consumer_key
      env['omniauth.strategy'].options[:client_secret] = PlatformContext.current.instance.facebook_consumer_key
    end
  end

  def friend_ids
    begin
      @friend_ids ||= connection.get_connections("me", "friends").collect{ |f| f["id"].to_s }
    rescue Koala::Facebook::AuthenticationError
      raise ::Authentication::InvalidToken
    end
  end

  def info
    begin
      @info ||= Info.new(connection.get_object('me'))
    rescue Koala::Facebook::AuthenticationError
      raise ::Authentication::InvalidToken
    end
  end

  class Info < BaseInfo

    def initialize(raw)
      @raw          = raw
      @uid          = raw["id"].presence
      @username     = raw["username"]
      @email        = raw["email"]
      @name         = raw["name"]
      @first_name   = raw["first_name"]
      @last_name    = raw["last_name"]
      @description  = raw["bio"]
      @image_url    = "http://graph.facebook.com/#{raw["id"]}/picture?type=large"
      @profile_url  = raw["link"]
      @website_url  = raw["website"]
      @location     = (raw["location"] || {})["name"]
      @verified     = raw['verified']
      @provider     = 'Facebook'
    end

  end

  private
  def connection
    @connection ||= Koala::Facebook::API.new(token)
  end

end
