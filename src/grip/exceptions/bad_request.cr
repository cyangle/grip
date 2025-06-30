module Grip
  module Exceptions
    class BadRequest < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::BAD_REQUEST
        @message = message if message
        @message = "Please provide a proper request to the endpoint." unless message
      end
    end
  end
end
