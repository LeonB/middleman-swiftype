require "middleman-swiftype"

describe "pushing content to swiftype" do
  it "pushes the darn thing" do
    Dir.chdir("spec/fixtures/swiftype-app") do
      expect_any_instance_of(::Swiftype::Client).to receive(:create_or_update_document).at_least(1).times
      Middleman::Cli::Swiftype.new.invoke(:swiftype)
    end
  end
end
