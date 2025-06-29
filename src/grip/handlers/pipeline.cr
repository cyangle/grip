module Grip
  module Handlers
    class Pipeline < Base
      CACHED_PIPES = {} of Array(Symbol) => Array(Middleware::Base)

      property pipeline : Hash(Symbol, Array(Middleware::Base))
      property http_handler : ::HTTP::Handler?
      property websocket_handler : ::HTTP::Handler?

      def initialize(
        @http_handler = nil,
        @websocket_handler = nil
      )
        @pipeline = Hash(Symbol, Array(Middleware::Base)).new
      end

      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      def call(context : ::HTTP::Server::Context)
        if (websocket_handler && match_via_websocket(context)) ||
           (http_handler && match_via_http(context))
          return call_next(context)
        end
        call_next(context)
      end

      def add_pipe(
        valve : Symbol,
        pipe : ::HTTP::Handler,
        http_handler : ::HTTP::Handler? = nil,
        websocket_handler : ::HTTP::Handler? = nil
      ) : Nil
        @http_handler = http_handler
        @websocket_handler = websocket_handler

        handlers = @pipeline[valve] ||= Array(Middleware::Base).new
        handlers << pipe
        handlers[-2]?.try &.next = pipe
      end

      def get(valve : Symbol) : Array(Middleware::Base)?
        @pipeline[valve]?
      end

      def get(valves : Array(Symbol)) : Array(Middleware::Base)
        return CACHED_PIPES[valves] if CACHED_PIPES.has_key?(valves)

        pipes = Array(Middleware::Base).new

        valves.each do |valve|
          @pipeline[valve]?.try &.each { |pipe| pipes << pipe }
        end

        CACHED_PIPES[valves] = pipes
        pipes
      end

      def get(valve : Nil) : Nil
        nil
      end

      def match_via_websocket(context : ::HTTP::Server::Context) : Bool
        return false unless websocket_handler = @websocket_handler
        ws_handler = websocket_handler.as(WebSocket)

        route = ws_handler.find_route("", context.request.path)
        return false unless route.found? && ws_handler.websocket_upgrade_request?(context)

        context.parameters = Parsers::ParameterBox.new(context.request, route.params)
        route.payload.process_pipeline(context, self)
        true
      end

      def match_via_http(context : ::HTTP::Server::Context) : Bool
        return false unless http_handler = @http_handler
        http = http_handler.as(HTTP)

        route = find_http_route(http, context)
        return false unless route.found?

        context.parameters = Parsers::ParameterBox.new(context.request, route.params)
        route.payload.process_pipeline(context, self)
        true
      end

      private def find_http_route(http : HTTP, context : ::HTTP::Server::Context) : Radix::Result(Route)
        route = http.find_route(context.request.method, context.request.path)
        route.found? ? route : http.find_route("ALL", context.request.path)
      end
    end
  end
end
