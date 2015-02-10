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
        self.delete_orphans if options.clean
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
  swiftype.process_html = lambda { |f| f.search('.//div[@class="linenodiv"]').remove }
  swiftype.generate_sections = lambda { |p| (p.metadata[:page]['tags'] ||= []) + (p.metadata[:page]['categories'] ||= []) }
  swiftype.generate_info = lambda { |f| TruncateHTML.truncate_html(strip_img(f.to_s), blog.options.summary_length, '...') }
  swiftype.generate_image = lambda { |p| "#{settings.url}#{p.metadata[:page]['banner']}" if p.metadata[:page]['banner'] }
end
EOF
      end

      def swiftype_options(shared_instance)
        require 'swiftype'
        require 'nokogiri'
        require 'digest'

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

        # https://github.com/swiftype/swiftype-rb
        ::Swiftype.configure do |config|
          config.api_key = options.api_key
        end

        swiftype_client = ::Swiftype::Client.new

        m_pages = shared_instance.sitemap.resources.find_all{|p| options.pages_selector.call(p) }
        m_pages.each do |p|
          external_id = Digest::MD5.hexdigest(p.url)
          title = p.metadata[:page]['title']
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

          # https://swiftype.com/documentation/crawler#schema
          # https://swiftype.com/documentation/meta_tags
          shared_instance.logger.info("Pushing contents of #{url} to swiftype")
          #next
          swiftype_client.create_or_update_document(options.engine_slug, 'page', {
              :external_id => external_id,
              :fields => fields
          })
        end
      end

      def delete_orphans
        shared_instance = ::Middleman::Application.server.inst
        options = self.swiftype_options(shared_instance)

        # https://github.com/swiftype/swiftype-rb
        ::Swiftype.configure do |config|
          config.api_key = options.api_key
        end

        per_page = 100

        swiftype_client = ::Swiftype::Client.new

        engine = swiftype_client.engine(options.engine_slug)
        pages = (engine['document_count']/per_page.to_f).ceil

        swiftype_documents = []
        for i in 1..pages
          swiftype_documents += swiftype_client.documents(options.engine_slug, 'page', i, per_page).collect{ |d| d['external_id'] }
        end

        m_pages = shared_instance.sitemap.resources.find_all{|p| options.pages_selector.call(p) }
        current_pages = m_pages.collect{ |p| Digest::MD5.hexdigest(p.url)}

        orphans = swiftype_documents - current_pages

        swiftype_client.destroy_documents(options.engine_slug, 'page', orphans) if orphans.any?
      end
    end
  end
end

