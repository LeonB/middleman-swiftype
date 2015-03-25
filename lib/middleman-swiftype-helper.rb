require 'swiftype'
require 'nokogiri'
require 'digest'

class Options < Struct.new(:api_key, :engine_slug, :pages_selector, :process_html, :generate_sections, :generate_info, :generate_image, :title_selector, :should_index); end

class MiddlemanSwiftypeHelper
  def initialize(plugin_options, shared_instance)
    @options = Options.new(plugin_options)
    @shared_instance = shared_instance
  end

  def swiftype_document_type
    "page"
  end

  def generate_swiftype_records
    records = []

    options = self.swiftype_options(@shared_instance, true)
    m_pages = @shared_instance.sitemap.resources.find_all{|p| options.pages_selector.call(p) }

    m_pages.each do |p|
      external_id = Digest::MD5.hexdigest(p.url)

      # optional selector for retrieving the page title
      if options.title_selector
        title = options.title_selector.call(@shared_instance, p)
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

      if options.should_index
        should_index = options.should_index.call(p, title)
        next unless should_index
      end

      fields = [
        {:name => 'title', :value => title, :type => 'string'},
        {:name => 'url', :value => url, :type => 'enum'},
        {:name => 'body', :value => body, :type => 'string'},
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
    options = self.swiftype_options(@shared_instance)
    # https://github.com/swiftype/swiftype-rb
    ::Swiftype.configure do |config|
      config.api_key = options.api_key
    end

    swiftype_client = ::Swiftype::Client.new

    records.each do |record|
      # https://swiftype.com/documentation/crawler#schema
      # https://swiftype.com/documentation/meta_tags
      url_field = record[:fields].find { |fields| fields[:name] == "url" }
      @shared_instance.logger.info("Pushing contents of #{url_field[:value]} to swiftype")
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
end