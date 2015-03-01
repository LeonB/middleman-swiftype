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
        if options[:"only-generate"]
          shared_instance.logger.info("Building content...")
          builder = Middleman::Cli::Build.new
          builder.build

          shared_instance.logger.info("Done. Creating search.json...")
          File.open("./#{Middleman::Application.build_dir}/search.json", "w") do |f|
            f.write(self.generate_swiftype_records.to_json)
          end
        else
          self.push_to_swiftype(self.generate_swiftype_records)
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
  swiftype.generate_image = lambda { |p| "#{settings.url}#{p.metadata[:page]['banner']}" if p.metadata[:page]['banner'] }
end
EOF
      end

      def swiftype_options(shared_instance, generate_only=false)
        require 'swiftype'
        require 'nokogiri'
        require 'digest'

        options = nil

        begin
          options = shared_instance.swiftype.options
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

      def generate_swiftype_records
        records = []

        options = self.swiftype_options(shared_instance, true)
        m_pages = shared_instance.sitemap.resources.find_all{|p| options.pages_selector.call(p) }

        m_pages.each do |p|
          external_id = Digest::MD5.hexdigest(p.url)

          # optional selector for retrieving the page title
          if options.title_selector
            title = options.title_selector.call(shared_instance, p)
          else
            title = p.metadata[:page]['title']
          end

          url = p.url
          sections = []
          body = ''
          info = ''
          image = ''

          f = Nokogiri::HTML.fragment(p.render(:layout => false))

          # optionally edit html
          if options.process_html
            options.process_html.call(f)
          end
          body = f.text

          if options.generate_sections
            sections = options.generate_sections.call(p)
          end

          # optionally generate extra info
          if options.generate_info
            info = options.generate_info.call(f)
          end

          # optional image
          if options.generate_image
            image = options.generate_image.call(p)
          end

          fields = [
            {:name => 'title', :value => title, :type => 'string'},
            {:name => 'url', :value => url, :type => 'enum'},
            {:name => 'body', :value => body, :type => 'text'},
            {:name => 'info', :value => info, :type => 'string'}
          ]

          if sections.length > 0
            {:name => 'sections', :value => sections, :type => 'string'}
          end

          if image
            fields << {:name => 'image', :value => image, :type => 'enum'}
          end

          records << {
            :external_id => external_id,
            :fields => fields
          }
        end

        records
      end

      def push_to_swiftype(records)
        options = self.swiftype_options(shared_instance)
        # https://github.com/swiftype/swiftype-rb
        ::Swiftype.configure do |config|
          config.api_key = options.api_key
        end

        swiftype_client = ::Swiftype::Client.new

        records.each do |record|
          # https://swiftype.com/documentation/crawler#schema
          # https://swiftype.com/documentation/meta_tags
          url_field = record[:fields].find { |fields| fields[:name] == "url" }
          shared_instance.logger.info("Pushing contents of #{url_field[:value]} to swiftype")
          #next
          begin
            swiftype_client.create_or_update_document(options.engine_slug, swiftype_document_type, {
                :external_id => record[:external_id],
                :fields => record[:fields]
            })
          rescue ::Swiftype::NonExistentRecord
            swiftype_client.create_document_type(options.engine_slug, swiftype_document_type)
            swiftype_client.create_or_update_document(options.engine_slug, 'page', {
                :external_id => record[:external_id],
                :fields => record[:fields]
            })
          end
        end
      end

      def shared_instance
        @shared_instance ||= Middleman::Application.server.inst
      end

      def swiftype_document_type
        "page"
      end
    end
  end
end
