module Grip
  module Middleware
    class PoweredByGrip
      include Base

      def call(context : HTTP::Server::Context)
        context.response.headers.merge!({"X-Powered-By" => "Grip/#{Grip::VERSION}"})
        context
      end
    end
  end
end
