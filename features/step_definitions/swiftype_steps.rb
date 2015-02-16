require "swiftype"

Given /^Swiftype expects to receive new search records$/ do
  expect_any_instance_of(::Swiftype::Client).to receive(:create_or_update_document).at_least(1).times
end
