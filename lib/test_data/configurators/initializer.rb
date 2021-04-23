module TestData
  module Configurators
    class Initializer
      def initialize
        @generator = InitializerGenerator.new
        @config = TestData.config
      end

      def verify
        pathname = Pathname.new("#{@config.pwd}/config/initializers/test_data.rb")
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
