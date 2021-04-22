require "rails/generators"

module TestData
  class EnvironmentFileGenerator < Rails::Generators::Base
    def call
      create_file "config/environments/test_data.rb", <<~RUBY
        require_relative "development"

        TestData.config do |config|
          # Where to store SQL dumps of the test_data database schema
          # config.schema_dump_path = "test/support/test_data/schema.sql"

          # Where to store SQL dumps of the test_data database test data
          # config.data_dump_path = "test/support/test_data/data.sql"

          # Where to store SQL dumps of the test_data database non-test data
          # config.non_test_data_dump_path = "test/support/test_data/non_test_data.sql"

          # Tables whose data shouldn't be loaded into tests
          # config.non_test_data_tables = ["ar_internal_metadata", "schema_migrations"]

          # Log level (valid values: [:debug, :info, :warn, :error, :quiet])
          # config.log_level = :info
        end

        Rails.application.configure do
          config.active_record.dump_schema_after_migration = false
        end
      RUBY
    end
  end
end
