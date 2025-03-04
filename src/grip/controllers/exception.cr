module Grip
  module Controllers
    module Exception
      macro included
        alias Context = ::HTTP::Server::Context

        include ::HTTP::Handler
        include Grip::Helpers::Singleton

        def call(context : Context) : Context
          context.html(context.exception)
        end
      end
    end
  end
end
