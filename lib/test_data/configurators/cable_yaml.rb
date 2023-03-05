require_relative "../yaml_loader"

module TestData
  module Configurators
    class CableYaml
      def initialize
        @generator = CableYamlGenerator.new
        @config = TestData.config
      end

      def verify
        if !File.exist?(@config.cable_yaml_full_path) ||
            YAMLLoader.load_file(@config.cable_yaml_full_path).key?("test_data")
          ConfigurationVerification.new(looks_good?: true)
        else
          ConfigurationVerification.new(problems: [
            "'#{@config.cable_yaml_path}' exists but does not contain a 'test_data' section"
          ])
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
