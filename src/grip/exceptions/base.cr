module Grip
  module Exceptions
    abstract class Base < Exception
      getter status_code : HTTP::Status

      def initialize(@message : String)
        @status_code = HTTP::Status::IM_A_TEAPOT
      end
    end
  end
end
