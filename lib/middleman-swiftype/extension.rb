# Require core library
require "middleman-core"

# Extension namespace
module Middleman
  module Swiftype

    class Options < Struct.new(:api_key, :engine_slug); end

    class << self
      def registered(app, options_hash={}, &block)
        app.send :include, Helpers

        options = Options.new(options_hash)
        yield options if block_given?

        app.after_configuration do
          # create app.swiftype
          swiftype(options)
        end
      end

      alias :included :registered
    end

    module Helpers
      # create app.swiftype
      def swiftype(options=nil)
        @_swiftype ||= Struct.new(:options).new(options)
      end
    end

  end
end
