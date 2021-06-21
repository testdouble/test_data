module TestData
  module Configurators
    class SecretsYaml
      def initialize
        @generator = SecretsYamlGenerator.new
        @config = TestData.config
      end

      def verify
        if !File.exist?(@config.secrets_yaml_full_path) ||
            YAML.load_file(@config.secrets_yaml_full_path).key?("test_data")
          ConfigurationVerification.new(looks_good?: true)
        else
          ConfigurationVerification.new(problems: [
            "'#{@config.secrets_yaml_path}' exists but does not contain a 'test_data' section"
          ])
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
