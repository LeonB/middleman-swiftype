require "middleman-swiftype"

describe "generating swiftype manifest files" do
  it "creates a search.json file" do
    Dir.chdir("spec/fixtures/swiftype-app") do
      task = Middleman::Cli::Swiftype.new
      task.invoke(:swiftype, [], {:'only-generate' => true})
      expect(File).to exist("build/search.json")
      system("rm build/search.json")
    end
  end
end
