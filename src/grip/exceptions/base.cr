module Grip
  module Exceptions
    class Base < Exception
      getter status_code : HTTP::Status = HTTP::Status::IM_A_TEAPOT

      def initialize(@status_code : HTTP::Status, @message : String)
      end
    end
  end
end
