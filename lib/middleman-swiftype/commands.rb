require 'middleman-core/cli'
require 'middleman-swiftype/pkg-info'
require 'middleman-swiftype-helper'

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

      desc "swiftype", "Push your documents to swiftype"
      method_option "clean",
        :type => :boolean,
        :aliases => "-c",
        :desc => "Remove orphaned files or directories on the remote host"
      method_option "only-generate",
        :type => :boolean,
        :aliases => "-g",
        :desc => "Generate a search.json file without pushing it"

      def swiftype
        mm_instance = Middleman::Application.server.inst
        generate_only = options[:"only-generate"]
        plugin_options = swiftype_options(mm_instance, generate_only)
        helper = MiddlemanSwiftypeHelper.new plugin_options

        if generate_only
          helper.generate_search_json
        else
          helper.push_to_swiftype(helper.generate_swiftype_records)
        end
      end

      protected

      def print_usage_and_die(message)
        raise Error, "ERROR: " + message + "\n" + <<EOF

You should follow one of the three examples below to setup the swiftype
extension in config.rb.

# Configuration of the swiftype extension
activate :swiftype do |swiftype|
  swiftype.api_key = 'MY_SECRET_API_KEY'
  swiftype.engine_slug = 'my_awesome_blog'
  swiftype.pages_selector = lambda { |p| p.path.match(/\.html/) && p.metadata[:options][:layout] == nil }
  swiftype.title_selector = lamda { |mm_instance, p| '...' }
  swiftype.process_html = lambda { |f| f.search('.//div[@class="linenodiv"]').remove }
  swiftype.generate_sections = lambda { |p| (p.metadata[:page]['tags'] ||= []) + (p.metadata[:page]['categories'] ||= []) }
  swiftype.generate_info = lambda { |f| TruncateHTML.truncate_html(strip_img(f.to_s), blog.options.summary_length, '...') }
  swiftype.generate_image = lambda { |p| "\#{settings.url}\#{p.metadata[:page]['banner']}" if p.metadata[:page]['banner'] }
  swiftype.should_index = lamda { |p, title| '...' }
end
EOF
      end

      def swiftype_options(mm_instance, generate_only)
        options = nil

        begin
          options = mm_instance.swiftype.options
        rescue
          print_usage_and_die "You need to activate the swiftype extension in config.rb."
        end

        return options if generate_only

        if (!options.api_key)
          print_usage_and_die "The swiftype extension requires you to set an api_key."
        end

        if (!options.engine_slug)
          print_usage_and_die "The swiftype extension requires you to set an engine_slug."
        end

        options
      end
    end
  end
end
