class SilentMissedImages
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] =~ /^\/instances\/\d+\/uploads\//
      [404, {}, []]
    else
      @app.call(env)
    end
  end

end
