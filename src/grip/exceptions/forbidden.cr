module Grip
  module Exceptions
    class Forbidden < Base      
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::FORBIDDEN

        super message if message
        super "You lack the privilege to access this endpoint." unless message
      end
    end
  end
end
