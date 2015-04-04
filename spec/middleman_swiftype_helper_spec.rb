require 'middleman-swiftype'

describe MiddlemanSwiftypeHelper do
  let :options do
    OpenStruct.new({
      :api_key => "API_KEY",
      :engine_slug => "middleman",
      :pages_selector => lambda { |p| p.path.match(/\.html/) && p.metadata[:options][:layout] == nil },
      :process_html => lambda { |f| f.search('.//div[@class="linenodiv"]').remove },
      :generate_sections => lambda { |p| (p.metadata[:page]['tags'] ||= []) + (p.metadata[:page]['categories'] ||= []) },
      :generate_info => lambda { |f| f.to_s },
      :generate_image => lambda { |p| "#{settings.url}#{p.metadata[:page]['banner']}" if p.metadata[:page]['banner'] }
    })
  end

  it 'generates JSON in which the body type is "string"' do
    Dir.chdir("fixtures/swiftype-app") do
      helper = MiddlemanSwiftypeHelper.new(options)
      json = helper.generate_swiftype_records
      body_type = json[0][:fields][2][:type]
      expect(body_type).to eq "string"
    end
  end
end
