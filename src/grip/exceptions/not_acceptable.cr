module Grip
  module Exceptions
    class NotAcceptable < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::NOT_ACCEPTABLE

        super "Please provide a proper request to the endpoint." unless message
        super message if message
      end
    end
  end
end
