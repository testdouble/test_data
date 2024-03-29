module TestData
  module Configurators
    class EnvironmentFile
      def initialize
        @generator = EnvironmentFileGenerator.new
        @config = TestData.config
      end

      def verify
        path = "config/environments/test_data.rb"
        pathname = Pathname.new("#{@config.pwd}/#{path}")
        if pathname.readable?
          ConfigurationVerification.new(looks_good?: true)
        else
          ConfigurationVerification.new(problems: [
            "'#{path}' is not readable"
          ])
        end
      end

      def configure
        @generator.call
      end
    end
  end
end
