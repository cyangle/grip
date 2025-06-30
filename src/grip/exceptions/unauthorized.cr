module Grip
  module Exceptions
    class Unauthorized < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::UNAUTHORIZED

        super message if message
        super "You are not authorized to access this endpoint." unless message
      end
    end
  end
end
