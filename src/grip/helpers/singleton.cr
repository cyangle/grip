module Grip
  module Helpers
    module Singleton
      macro included
        @@instance = new

        def self.instance
          @@instance
        end
      end
    end
  end
end
