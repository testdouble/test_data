module TestData
  module Configurators
    def self.all
      [
        EnvironmentFile,
        Initializer,
        DatabaseYaml,
        SecretsYaml,
        WebpackerYaml
      ].map(&:new)
    end
  end
end
