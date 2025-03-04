module Grip
  module Handlers
    struct Route
      getter method : String
      getter path : String
      getter handler : ::HTTP::Handler
      getter via : Array(Symbol)
      getter override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)?

      def initialize(
        @method : String,
        @path : String,
        @handler : ::HTTP::Handler,
        via : Symbol | Array(Symbol) | Nil = nil,
        @override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      )
        @via = normalize_via(via)
      end

      def process_pipeline(
        context : ::HTTP::Server::Context,
        pipeline_handler : Grip::Handlers::Pipeline
      ) : ::HTTP::Server::Context
        execute_pipeline(context, pipeline_handler)
        context
      end

      def execute_override(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        @override.try(&.call(context))
        context
      end

      private def normalize_via(via : Symbol | Array(Symbol) | Nil) : Array(Symbol)
        case via
        when Symbol
          [via]
        when Array(Symbol)
          via
        else
          [] of Symbol
        end
      end

      private def execute_pipeline(
        context : ::HTTP::Server::Context,
        pipeline_handler : Grip::Handlers::Pipeline
      ) : Nil
        pipeline_handler.get(@via).each(&.call(context))
      end
    end
  end
end
