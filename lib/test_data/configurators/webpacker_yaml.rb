module TestData
  module Configurators
    class WebpackerYaml
      def initialize
        @generator = WebpackerYamlGenerator.new
        @webpacker_config = Wrap::WebpackerConfig.new
      end

      def verify
        if @webpacker_config.no_user_config_exists?
          ConfigurationVerification.new(looks_good?: true)
        elsif (user_config = @webpacker_config.user_config).nil?
          ConfigurationVerification.new(problems: [
            "`#{@webpacker_config.relative_user_config_path}' is not valid YAML"
          ])
        elsif !user_config.key?("test_data")
          ConfigurationVerification.new(problems: [
            "`#{@webpacker_config.relative_user_config_path}' does not contain a `test_data' section"
          ])
        elsif (entries = @webpacker_config.required_entries_missing_from_test_data_config)
          ConfigurationVerification.new(problems: [
            "`#{@webpacker_config.relative_user_config_path}' is missing #{"entry".pluralize(entries.size)} #{entries.map { |(k, v)| "`#{k}' (default: #{v.inspect})" }.join(", ")} in its `test_data' section"
          ])
        else
          ConfigurationVerification.new(looks_good?: true)
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
