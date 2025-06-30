module Grip
  module Exceptions
    class NotAcceptable < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::NOT_ACCEPTABLE
        @message =  message if message
        @message =  "Please provide a proper request to the endpoint." unless message
      end
    end
  end
end
