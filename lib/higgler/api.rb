module Higgler
  class API
    include Singleton

    attr_reader :router

    def initialize
      @router = Higgler::API::Router.instance
    end

    def call(env)
      path = env['PATH_INFO']
      route = @router.route_for(env['REQUEST_METHOD'], path)
      if route
        route.call(params(env), path)
      else
        [404, { 'Content-Type' => 'application/json' }, ['Route not found']]
      end
    end

    private

    def params(env)
      token = env['HTTP_AUTHENTICATION_TOKEN']
      unless token.present?
        auth = Rack::Auth::Basic::Request.new(env)
        if auth.provided? && auth.basic?
          username, password = auth.credentials
          user = User.find_by_email(username)
          token = user.auth_token if user.present? && user.valid_password?(password)
        end
      end
      Rack::Request.new(env).params.merge({ 'auth_token' => token })
    end
  end
end
