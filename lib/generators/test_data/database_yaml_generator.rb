require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class DatabaseYamlGenerator < Rails::Generators::Base
    def call
      if Configurators::DatabaseYaml.new.verify.looks_good?
        TestData.log.info "'test_data' section already defined in config/database.yml"
      else
        app_name = Rails.application.railtie_name.chomp("_application")
        inject_into_file "config/database.yml", before: BEFORE_TEST_STANZA_REGEX do
          <<~YAML

            # Used in conjunction with the test_data gem
            test_data:
              <<: *default
              database: #{app_name}_test_data
          YAML
        end
      end
    end
  end
end
