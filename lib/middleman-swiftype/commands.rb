require "middleman-core/cli"

require "middleman-swiftype/pkg-info"

PACKAGE = "#{Middleman::Swiftype::PACKAGE}"
VERSION = "#{Middleman::Swiftype::VERSION}"

module Middleman
  module Cli

    # This class provides a "swiftype" command for the middleman CLI.
    class Swiftype < Thor
      include Thor::Actions

      check_unknown_options!

      namespace :swiftype

      # Tell Thor to exit with a nonzero exit code on failure
      def self.exit_on_failure?
        true
      end

      desc "swiftype", "Push you documents to swiftype"
      method_option "clean",
        :type => :boolean,
        :aliases => "-c",
        :desc => "Remove orphaned files or directories on the remote host"

      def swiftype
        self.push_to_swiftype
      end

      protected

      def print_usage_and_die(message)
        raise Error, "ERROR: " + message + "\n" + <<EOF

You should follow one of the three examples below to setup the swiftype
extension in config.rb.

# To swiftype the build directory to a remote host via rsync:
activate :swiftype do |swiftype|
  swiftype.api_key = 'MY_SECRET_API_KEY'
  swiftype.engine_name = 'my_awesome_blog'
end
EOF
      end

      def swiftype_options(shared_instance)
        require 'swiftype'

        options = nil

        begin
          options = shared_instance.swiftype.options
        rescue
          print_usage_and_die "You need to activate the swiftype extension in config.rb."
        end

        if (!options.api_key)
          print_usage_and_die "The swiftype extension requires you to set an api_key."
        end

        if (!options.engine_slug)
          print_usage_and_die "The swiftype extension requires you to set an engine_slug."
        end

        options
      end

      def push_to_swiftype
        shared_instance = ::Middleman::Application.server.inst
        options = self.swiftype_options(shared_instance)

        # shared_instance.sitemap.resources.find_all do | a |
        #   print a.path + "\n"
        # end

        pages = shared_instance.sitemap.resources
        pages = pages.find_all{|p| p.path.match(/\.html/) && !p.directory_index? }

        pages.each do |p|
          # print p.url + "\n"
          print "---------------------------------------\n"
          print p.body
          print "\n---------------------------------------\n"
          asds()

          # print p.metadata
          # print "\n"

        end

        # https://github.com/swiftype/swiftype-rb
        # ::Swiftype.configure do |config|
        #   config.api_key = options.api_key
        # end

        # # engine = ::Swiftype::Engine.new(:name => 'asdasd')
        # # engine.create!

        # engine = ::Swiftype::Engine.find(options.engine_slug)
        # page = engine.document_type('page')
        # print page.documents

        # https://swiftype.com/documentation/crawler#schema
        # https://swiftype.com/documentation/meta_tags
        # title
        # url
        # sections
        # body

      end

    end
  end
end
