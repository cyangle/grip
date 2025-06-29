module Grip
  # `Grip::Application` is a building class which initializes the crucial parts of the
  # web-framework.
  module Application
    macro included
      include Grip::Macros::Dsl

      DEFAULT_HOST        = "0.0.0.0"
      DEFAULT_PORT        = 4004
      DEFAULT_ENVIRONMENT = "development"
      DEFAULT_REUSE_PORT  = false

      property environment : String = DEFAULT_ENVIRONMENT
      property host : String = DEFAULT_HOST
      property port : Int32 = DEFAULT_PORT
      property? reuse_port : Bool = DEFAULT_REUSE_PORT

      getter scopes : Array(String) = [] of String
      getter valves : Array(Symbol) = [] of Symbol
      getter valve : Symbol? = nil

      getter handlers : Array(HTTP::Handler) = [] of HTTP::Handler

      # SSL/TLS configuration
      def key_file : String
        ENV["KEY"]? || ""
      end

      def cert_file : String
        ENV["CERTIFICATE"]? || ""
      end

      {% unless flag?(:ssl) %}
        def ssl : Bool
          false
        end
      {% else %}
        def ssl : OpenSSL::SSL::Context::Server?
          return nil if key_file.empty? || cert_file.empty?

          context = OpenSSL::SSL::Context::Server.new
          context.private_key = key_file
          context.certificate_chain = cert_file
          context
        end
      {% end %}

      def scheme : String
        ssl ? "https" : "http"
      end

      # Server setup and running
      def server : HTTP::Server
        HTTP::Server.new(@handlers)
      end

      def run
        server_instance = server
        bind_server(server_instance)

        Log.info { "Listening at #{scheme}://#{host}:#{port}" }
        setup_signal_handling unless environment == "test"
        server_instance.listen unless environment == "test"
      end

      private def bind_server(server : HTTP::Server)
        unless server.each_address { |_| break true }
          {% if flag?(:ssl) %}
            if ssl_context = ssl
              server.bind_tls(host, port, ssl_context, reuse_port?)
            else
              server.bind_tcp(host, port, reuse_port?)
            end
          {% else %}
            server.bind_tcp(host, port, reuse_port?)
          {% end %}
        end
      end

      private def setup_signal_handling
        {% begin %}
          {% version = Crystal::VERSION.gsub(/[^0-9.]/, "").split(".").map(&.to_i) %}
          {% major = version[0] %}
          {% minor = version[1] %}

          # Crystal version-specific signal handling
          {% if major < 1 %}
            Signal::INT.trap { exit }
          {% elsif major == 1 && minor < 12 %}
            Process.on_interrupt { exit }
          {% else %}
            Process.on_terminate { exit }
          {% end %}
        {% end %}
      end
    end
  end
end
