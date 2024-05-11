require "http"
require "http/web_socket"
require "json"
require "uri"
require "radix"
require "base64"
require "uuid"
require "log"
require "crypto/subtle"
require "exception_page"
require "openssl"

require "./grip/exceptions/base"
require "./grip/exceptions/*"
require "./grip/support/*"
require "./grip/minuscule/*"
require "./grip/parsers/*"
require "./grip/macros/*"
require "./grip/extensions/*"
require "./grip/helpers/*"
require "./grip/handlers/*"
require "./grip/controllers/*"
require "./grip/routers/route"
require "./grip/routers/*"
require "./grip/*"

module Grip; end

class Application < Grip::Application
    def initialize()
        super("development", false)
    end
end

app = Application.new
app.run