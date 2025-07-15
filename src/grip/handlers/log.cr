module Grip
  module Handlers
    class Log < Base
      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil,
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        elapsed_time = measure_request_time(context)
        log_request(context, elapsed_time)
        context
      end

      private def measure_request_time(context : ::HTTP::Server::Context) : Time::Span
        Time.measure { call_next(context) }
      end

      private def log_request(context : ::HTTP::Server::Context, elapsed : Time::Span) : Nil
        ::Log.info do
          [
            context.response.status_code,
            context.request.method,
            context.request.resource,
            format_elapsed_time(elapsed),
          ].join(" ")
        end
      end

      private def format_elapsed_time(elapsed : Time::Span) : String
        millis = elapsed.total_milliseconds
        if millis >= 1
          "#{millis.round(2)}ms"
        else
          "#{(millis * 1000).round(2)}µs"
        end
      end
    end
  end
end
