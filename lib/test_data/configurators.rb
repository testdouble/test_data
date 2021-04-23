module TestData
  module Configurators
    def self.all
      [
        EnvironmentFile,
        Initializer,
        DatabaseYaml,
        WebpackerYaml
      ].map(&:new)
    end
  end
end
