module Grip
  module Exceptions
    class Generic < Base
      def initialize
        @status_code = HTTP::Status::SERVICE_UNAVAILABLE
        @message = "Something went wrong, please try again."
      end
    end
  end
end
