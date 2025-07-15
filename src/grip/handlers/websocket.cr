module Grip
  module Handlers
    class WebSocket < Base
      CACHE_LIMIT = 1024

      getter routes : Radix::Tree(Route)
      getter cache : Hash(String, Radix::Result(Route))

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Hash(String, Radix::Result(Route)).new
      end

      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil,
      ) : Nil
        route = Route.new("", path, handler, via, nil)
        add_to_radix_tree(path, route)
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        lookup_path = "/ws#{path}"

        return @cache[lookup_path] if @cache.has_key?(lookup_path)

        route = @routes.find(lookup_path)

        if route.found?
          @cache.clear if @cache.size >= CACHE_LIMIT
          @cache[lookup_path] = route
        end

        route
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        route = find_route("", context.request.path)
        return call_next(context) || context unless route.found? && websocket_upgrade_request?(context)

        context.parameters ||= Grip::Parsers::ParameterBox.new(context.request, route.params)
        route.payload.handler.call(context)

        context
      end

      def websocket_upgrade_request?(context : ::HTTP::Server::Context) : Bool
        return false unless upgrade = context.request.headers["Upgrade"]?
        return false unless upgrade.compare("websocket", case_insensitive: true) == 0

        context.request.headers.includes_word?("Connection", "Upgrade")
      end

      private def add_to_radix_tree(path : String, websocket : Route) : Nil
        node = build_radix_path(path)
        @routes.add(node, websocket)
      end

      private def build_radix_path(path : String) : String
        "/ws#{path}"
      end
    end
  end
end
