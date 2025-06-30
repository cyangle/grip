module Grip
  module Exceptions
    class InternalServerError < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::INTERNAL_SERVER_ERROR
        @message =  message if message
        @message =  "Please try again later or contact the server administration team." unless message
      end
    end
  end
end
