module TestData
  module Configurators
    def self.all
      [
        EnvironmentFile,
        Initializer,
        CableYaml,
        DatabaseYaml,
        SecretsYaml,
        WebpackerYaml
      ].map(&:new)
    end
  end
end
