module TestData
  module Configurators
    class WebpackerYaml
      def initialize
        @generator = WebpackerYamlGenerator.new
        @config = TestData.config
      end

      def verify
        path = "config/webpacker.yml"
        pathname = Pathname.new("#{@config.pwd}/#{path}")
        return ConfigurationVerification.new(looks_good?: true) unless pathname.readable?
        yaml = load_yaml(pathname)
        if yaml.nil?
          ConfigurationVerification.new(problems: [
            "'#{path}' is not valid YAML"
          ])
        elsif !yaml.key?("test_data")
          ConfigurationVerification.new(problems: [
            "'#{path}' does not contain a 'test_data' section"
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
