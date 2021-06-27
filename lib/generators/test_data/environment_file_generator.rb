require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class EnvironmentFileGenerator < Rails::Generators::Base
    def call
      create_file "config/environments/test_data.rb", <<~RUBY
        # Load the development environment as a starting point
        require_relative "development"

        Rails.application.configure do
          # Don't persist schema.rb or structure.sql after test_data is migrated
          config.active_record.dump_schema_after_migration = false
        end
      RUBY
    end
  end
end
