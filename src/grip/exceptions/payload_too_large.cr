module Grip
  module Exceptions
    class PayloadTooLarge < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::PAYLOAD_TOO_LARGE

        super message if message
        super "Your request to the endpoint has been denied, please provide a proper payload." unless message
      end
    end
  end
end
