require_relative "../configuration_verification"
require_relative "../../generators/test_data/webpacker_yaml_generator"

module TestData
  module Configurators
    class WebpackerYaml
      def initialize
        @generator = WebpackerYamlGenerator.new
        @config = TestData.config
      end

      def verify
        pathname = Pathname.new("#{@config.pwd}/config/webpacker.yml")
        return ConfigurationVerification.new(looks_good?: true) unless pathname.readable?
        yaml = load_yaml(pathname)
        if yaml.nil?
          ConfigurationVerification.new(problems: [
            "'#{pathname}' is not valid YAML"
          ])
        elsif !yaml.key?("test_data")
          ConfigurationVerification.new(problems: [
            "'#{pathname}' does not contain a 'test_data' section"
          ])
        else
          ConfigurationVerification.new(looks_good?: true)
        end
      end

      def configure
        @generator.call
      end

      private

      def load_yaml(pathname)
        YAML.load_file(pathname)
      rescue
      end
    end
  end
end
