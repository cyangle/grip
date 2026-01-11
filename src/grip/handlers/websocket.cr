module Grip
  module Handlers
    class WebSocket < Base
      CACHE_SIZE = 4096
      CACHE_MASK = CACHE_SIZE - 1

      getter routes : Radix::Tree(Route)

      @cache : Array(Tuple(UInt64, Radix::Result(Route)?))

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Array(Tuple(UInt64, Radix::Result(Route)?)).new(CACHE_SIZE) { {0_u64, nil} }
      end

      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil,
      ) : Nil
        route = Route.new("", path, handler, via, nil)
        @routes.add(radix_path(path), route)
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        hash = path_hash(path)

        # Check cache
        if cached = cache_lookup(hash)
          return cached
        end

        # Radix lookup
        result = @routes.find(radix_path(path))
        cache_store(hash, result) if result.found?
        result
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        # Fast path: check WebSocket upgrade first (cheaper than route lookup)
        return call_next(context) || context unless websocket_upgrade_request?(context)

        route = find_route("", context.request.path)
        return call_next(context) || context unless route.found?

        context.parameters ||= Grip::Parsers::ParameterBox.new(context.request, route.params)
        route.payload.handler.call(context)

        context
      end

      @[AlwaysInline]
      def websocket_upgrade_request?(context : ::HTTP::Server::Context) : Bool
        headers = context.request.headers

        # Check Upgrade header exists and is "websocket"
        upgrade = headers["Upgrade"]?
        return false unless upgrade
        return false unless upgrade_is_websocket?(upgrade)

        # Check Connection header contains "Upgrade"
        headers.includes_word?("Connection", "Upgrade")
      end

      @[AlwaysInline]
      private def upgrade_is_websocket?(upgrade : String) : Bool
        return false unless upgrade.bytesize == 9 # "websocket".size

        # Case-insensitive compare without allocation
        upgrade.compare("websocket", case_insensitive: true) == 0
      end

      @[AlwaysInline]
      private def cache_lookup(hash : UInt64) : Radix::Result(Route)?
        slot = hash & CACHE_MASK

        4.times do |i|
          idx = (slot + i) & CACHE_MASK
          entry = @cache.unsafe_fetch(idx)

          return entry[1] if entry[0] == hash && entry[1]
          break if entry[0] == 0_u64 && i > 0
        end

        nil
      end

      @[AlwaysInline]
      private def cache_store(hash : UInt64, result : Radix::Result(Route)) : Nil
        slot = hash & CACHE_MASK

        4.times do |i|
          idx = (slot + i) & CACHE_MASK
          entry = @cache.unsafe_fetch(idx)

          if entry[0] == 0_u64 || entry[0] == hash
            @cache[idx] = {hash, result}
            return
          end
        end

        @cache[slot] = {hash, result}
      end

      @[AlwaysInline]
      private def path_hash(path : String) : UInt64
        hash = 0xcbf29ce484222325_u64 # FNV offset basis
        fnv_prime = 0x100000001b3_u64

        path.each_byte do |byte|
          hash ^= byte.to_u64
          hash &*= fnv_prime
        end

        hash
      end

      @[AlwaysInline]
      private def radix_path(path : String) : String
        String.build(3 + path.bytesize) do |io|
          io << "/ws"
          io << path
        end
      end
    end
  end
end
