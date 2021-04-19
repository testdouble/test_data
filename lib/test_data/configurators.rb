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
