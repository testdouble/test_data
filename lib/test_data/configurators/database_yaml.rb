require_relative "../configuration_verification"
require_relative "../../generators/test_data/database_yaml_generator"

module TestData
  module Configurators
    class DatabaseYaml
      def initialize
        @generator = DatabaseYamlGenerator.new
        @config = TestData.config
      end

      def verify
        if @config.database_yaml.key?("test_data")
          ConfigurationVerification.new(looks_good?: true)
        else
          ConfigurationVerification.new(problems: [
            "'#{@config.database_yaml_path}' does not contain a 'test_data' section"
          ])
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
