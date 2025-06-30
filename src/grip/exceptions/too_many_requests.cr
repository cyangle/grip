module Grip
  module Exceptions
    class TooManyRequests < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::TOO_MANY_REQUESTS

        super message if message
        super "Your request to the endpoint has been limited, please try again later." unless message
      end
    end
  end
end
