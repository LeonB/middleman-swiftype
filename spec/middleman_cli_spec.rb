require "middleman-swiftype"
require 'middleman-core/profiling'

describe "running the middleman cli" do
  it "generates 'search.json'" do
    Dir.chdir("fixtures/swiftype-app") do
      ENV['MM_ROOT'] = Dir.pwd
      builder = Middleman::Cli::Build.new
      builder.invoke(:build)
      expect(File).to exist("build/search.json")
      system("rm -rf build/*")
    end
  end
end
