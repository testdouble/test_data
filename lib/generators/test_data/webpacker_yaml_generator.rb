require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class WebpackerYamlGenerator < Rails::Generators::Base
    AFTER_DEVELOPMENT_WEBPACK_STANZA_REGEX = /^development:/
    AFTER_TEST_DATA_WEBPACK_STANZA_REGEX = /^test_data:\n  <<: \*development/

    def call
      configurator = Configurators::WebpackerYaml.new
      webpacker_config = Wrap::WebpackerConfig.new

      if configurator.verify.looks_good?
        TestData.log.debug "'test_data' section looks good in `config/webpacker.yml'"
      else
        unless webpacker_config.user_config.key?("test_data")
          inject_into_file "config/webpacker.yml", after: AFTER_DEVELOPMENT_WEBPACK_STANZA_REGEX do
            " &development"
          end
          inject_into_file "config/webpacker.yml", before: BEFORE_TEST_STANZA_REGEX do
            <<~YAML

              # Used in conjunction with the test_data gem
              test_data:
                <<: *development

            YAML
          end
        end

        if (missing_entries = webpacker_config.required_entries_missing_from_test_data_config)
          inject_into_file "config/webpacker.yml", after: /^test_data:\n/ do
            missing_entries.map { |(key, val)|
              "  #{key}: #{val.inspect}\n"
            }.join
          end
        end
      end
    end
  end
end
