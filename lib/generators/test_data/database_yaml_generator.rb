require "rails/generators"

require "test_data/configurators/database_yaml"

module TestData
  class DatabaseYamlGenerator < Rails::Generators::Base
    BEFORE_TEST_DATABASE_STANZA_REGEX = /^$\n(?:^\#.*\n)*^test:/

    def call
      if Configurators::DatabaseYaml.new(pwd: Rails.root).verify.looks_good?
        warn "'test_data' section already defined in config/database.yml"
      else
        app_name = Rails.application.railtie_name.chomp("_application")
        inject_into_file "config/database.yml", before: BEFORE_TEST_DATABASE_STANZA_REGEX do
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
