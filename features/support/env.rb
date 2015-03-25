require "cucumber/rspec/doubles"

PROJECT_ROOT_PATH = File.dirname(File.dirname(File.dirname(__FILE__)))
require "middleman-core"
require "middleman-core/step_definitions"
require File.join(PROJECT_ROOT_PATH, 'lib', 'middleman-swiftype')

# TODO: dammit. cannot figure out how to mock/stub/etc this call. Tried monkey patching and refinements :/
::Swiftype::Client.class_eval do
  module Document
    def create_or_update_document(engine_id, document_type_id, document={})
      puts "monkey patch"
    end
  end
end