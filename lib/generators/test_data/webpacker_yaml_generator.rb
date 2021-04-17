require "rails/generators"

require "test_data/configurators/webpacker_yaml"

module TestData
  class WebpackerYamlGenerator < Rails::Generators::Base
    AFTER_DEVELOPMENT_WEBPACK_STANZA_REGEX = /^development:/
    BEFORE_TEST_WEBPACK_STANZA_REGEX = /^$\n(?:^\#.*\n)*^test:/

    def call
      if Configurators::WebpackerYaml.new(pwd: Rails.root).verify.looks_good?
        warn "'test_data' section already defined in config/webpacker.yml"
      else
        inject_into_file "config/webpacker.yml", after: AFTER_DEVELOPMENT_WEBPACK_STANZA_REGEX do
          " &development"
        end
        inject_into_file "config/webpacker.yml", before: BEFORE_TEST_WEBPACK_STANZA_REGEX do
          <<~YAML

            # Used in conjunction with the test_data gem
            test_data:
              <<: *development
          YAML
        end
      end
    end
  end
end
