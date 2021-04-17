require_relative "configurators/environment_file"
require_relative "configurators/database_yaml"
require_relative "configurators/webpacker_yaml"

module TestData
  module Configurators
    def self.all
      [
        EnvironmentFile,
        DatabaseYaml,
        WebpackerYaml
      ].map(&:new)
    end
  end
end
