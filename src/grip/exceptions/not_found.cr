module Grip
  module Exceptions
    class NotFound < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::NOT_FOUND

        super message if message
        super "The endpoint you have requested was not found on the server." unless message
      end
    end
  end
end
