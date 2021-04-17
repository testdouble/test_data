require_relative "../configuration_verification"
require_relative "../../generators/test_data/environment_file_generator"

module TestData
  module Configurators
    class EnvironmentFile
      def initialize
        @generator = EnvironmentFileGenerator.new
        @config = TestData.config
      end

      def verify
        pathname = Pathname.new("#{@config.pwd}/config/environments/test_data.rb")
        if pathname.readable?
          ConfigurationVerification.new(looks_good?: true)
        else
          ConfigurationVerification.new(problems: [
            "'#{pathname}' is not readable"
          ])
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
