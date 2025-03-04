module Grip
  module Middleware
    module Base
      macro included
        include ::HTTP::Handler
      end
    end
  end
end
