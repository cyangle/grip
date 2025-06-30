module Grip
  module Exceptions
    class MethodNotAllowed < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::METHOD_NOT_ALLOWED

        super "Please provide a proper request to the endpoint." unless message
        super message if message
      end
    end
  end
end
