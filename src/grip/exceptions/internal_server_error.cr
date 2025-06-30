module Grip
  module Exceptions
    class InternalServerError < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::INTERNAL_SERVER_ERROR

        super message if message
        super "Please try again later or contact the server administration team." unless message
      end
    end
  end
end
