activate :swiftype do |swiftype|
  swiftype.api_key = "API_KEY"
  swiftype.engine_slug = "middleman"
  swiftype.pages_selector = lambda { |p| p.path.match(/\.html/) && p.metadata[:options][:layout] == nil }
  swiftype.process_html = lambda { |f| f.search('.//div[@class="linenodiv"]').remove }
  swiftype.generate_sections = lambda { |p| (p.metadata[:page]['tags'] ||= []) + (p.metadata[:page]['categories'] ||= []) }
  swiftype.generate_info = lambda { |f| f.to_s }
  swiftype.generate_image = lambda { |p| "#{settings.url}#{p.metadata[:page]['banner']}" if p.metadata[:page]['banner'] }
end
