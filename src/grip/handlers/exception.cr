module Grip
  module Handlers
    class Exception < Base
      alias ExceptionHandler = ::HTTP::Handler

      property environment : String = Grip::Application::DEFAULT_ENVIRONMENT
      property handlers : Hash(String, ExceptionHandler)

      def initialize
        @handlers = Hash(String, ExceptionHandler).new
      end

      def add_route(
        verb : String,
        path : String,
        handler : ExceptionHandler,
        via : Symbol | Array(Symbol) | Nil = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        call_next(context) || context
      rescue ex : ::Exception
        return context if context.response.closed?
        handle_exception(context, ex)
      end

      private def handle_exception(context : ::HTTP::Server::Context, exception : ::Exception) : ::HTTP::Server::Context
        status_code = determine_status_code(exception, context)
        process_exception(context, exception, status_code)
      end

      private def determine_status_code(exception : ::Exception, context : ::HTTP::Server::Context) : Int32
        case exception
        when Grip::Exceptions::Base
          exception.status_code.value
        else
          context.response.status_code
        end
      end

      private def process_exception(
        context : ::HTTP::Server::Context,
        exception : ::Exception,
        status_code : Int32
      ) : ::HTTP::Server::Context
        return context if context.response.closed?

        if handler = @handlers[exception.class.name]?
          execute_custom_handler(context, handler, exception, status_code)
        else
          render_default_error(context, exception, status_code)
        end
      end

      private def execute_custom_handler(
        context : ::HTTP::Server::Context,
        handler : ExceptionHandler,
        exception : ::Exception,
        status_code : Int32
      ) : ::HTTP::Server::Context
        context.response.status_code = status_code
        context.exception = exception

        updated_context = handler.call(context)
        context.response.close

        updated_context || context
      end

      private def render_default_error(
        context : ::HTTP::Server::Context,
        exception : ::Exception,
        status_code : Int32
      ) : ::HTTP::Server::Context
        if environment == "development"
          context.response.status_code = status_code.clamp(400, 599)
          context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
          context.response.print(Grip::Minuscule::ExceptionPage.new(context, exception))
        else
          context.response.status_code = 500
          context.response.print("500 Internal Server Error")
        end

        context.response.close
        context
      end
    end
  end
end
