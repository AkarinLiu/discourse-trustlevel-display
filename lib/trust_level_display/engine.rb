# frozen_string_literal: true

module ::TrustLevelDisplay
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace TrustLevelDisplay
    config.autoload_paths << File.join(config.root, "lib")
  end
end
