module Grip
  module Handlers
    abstract class Base
      include HTTP::Handler

      abstract def call(context : HTTP::Server::Context)
      abstract def add_route(verb : String, path : String, handler : HTTP::Handler, via : Symbol? | Array(Symbol)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?) : Nil
      abstract def find_route(verb : String, path : String) : Radix::Result(Route)
    end
  end
end
