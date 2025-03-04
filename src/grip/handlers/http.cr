module Grip
  module Handlers
    class HTTP < Base
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
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
        route = Route.new(verb, path, handler, via, override)
        add_to_radix_tree(verb, path, route)
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        lookup_path = build_radix_path(verb, path)

        if cached_route = @cache[lookup_path]?
          return cached_route
        end

        route = @routes.find(lookup_path)
        cache_route(lookup_path, route) if route.found?

        route
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        return context if context.response.closed?

        route = resolve_route(context.request.method, context.request.path)
        raise Exceptions::NotFound.new unless route.found?

        context.parameters ||= Grip::Parsers::ParameterBox.new(context.request, route.params)
        execute_route(route.payload, context)

        context
      end

      private def resolve_route(verb : String, path : String) : Radix::Result(Route)
        route = find_route(verb, path)
        route.found? ? route : find_route("ALL", path)
      end

      private def execute_route(route : Route, context : ::HTTP::Server::Context) : Nil
        if route.override
          route.execute_override(context)
        else
          route.handler.call(context)
        end
      end

      private def build_radix_path(verb : String, path : String) : String
        "/#{verb}#{path}"
      end

      private def add_to_radix_tree(verb : String, path : String, route : Route) : Nil
        @routes.add(build_radix_path(verb, path), route)
      end

      private def cache_route(lookup_path : String, route : Radix::Result(Route)) : Nil
        @cache.clear if @cache.size >= CACHE_LIMIT
        @cache[lookup_path] = route
      end
    end
  end
end
