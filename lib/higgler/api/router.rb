module Higgler
  class API
    class Route
      attr_reader :controller, :action, :pattern, :keys, :method

      def initialize(controller, action, pattern, keys, method)
        @controller = controller
        @keys = keys
        @action = action
        @pattern = pattern
        @method = method
      end

      def call(params = {}, path = '')
        params = params.merge get_keyed_params(path)
        @controller.new.call(@action, params)
      end

      def get_keyed_params(path)
        params = {}
        match = @pattern.match(path)
        values = match.captures
        @keys.zip(values) { |key, value| params[key] = value }
        params
      end
    end

    class Router
      include Singleton

      def initialize
        @routes = {}
      end

      def route_for(method, path)
        @routes[method].find { |r| path =~ r.pattern } if @routes[method]
      end

      def draw(&block)
        instance_exec(&block)
      end

      def get(path, action, controller)
        add_route(path, action, controller, 'GET')
      end

      def post(path, action, controller)
        add_route(path, action, controller, 'POST')
      end

      def put(path, action, controller)
        add_route(path, action, controller, 'PUT')
      end

      def delete(path, action, controller)
        add_route(path, action, controller, 'DELETE')
      end

      private

      def add_route(path, action, controller, method)
        keys = []
        nodes = path.split('/').map! do |node|
          # Get keys and replace by ignore pattern.
          node.gsub(/(:\w+|\*)/) do |_match|
            keys << Regexp.last_match[0][1..-1].to_sym
            '([^/?#]+)'
          end
        end
        postfix = path =~ %r{\/\z} ? '/*' : ''
        pattern = /\A#{nodes.join('/')}#{postfix}\z/
        (@routes[method] ||= []) << Route.new(controller, action, pattern, keys, method)
      end
    end
  end
end
