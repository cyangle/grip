module Grip
  module Exceptions
    class RequestTimeout < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::REQUEST_TIMEOUT

        super message if message
        super "Your request to the endpoint has timed out." unless message
      end
    end
  end
end
