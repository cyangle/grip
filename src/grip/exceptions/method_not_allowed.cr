module Grip
  module Exceptions
    class MethodNotAllowed < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::METHOD_NOT_ALLOWED
        @message =  message if message
        @message =  "Please provide a proper request to the endpoint." unless message
      end
    end
  end
end
