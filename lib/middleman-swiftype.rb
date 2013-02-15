require "middleman-core"

require "middleman-swiftype/commands"

::Middleman::Extensions.register(:swiftype) do
  require "middleman-swiftype/extension"
  ::Middleman::Swiftype
end
