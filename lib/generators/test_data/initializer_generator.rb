require "rails/generators"
require_relative "../../test_data/generator_support"

module TestData
  class InitializerGenerator < Rails::Generators::Base
    def call
      create_file "config/initializers/test_data.rb", <<~RUBY
        return unless defined?(TestData)

        TestData.config do |config|
          # Hook run after test data is loaded by `TestData.uses_test_data`,
          #   but before a savepoint is taken
          # config.after_test_data_load { }

          # Hook run after test data is truncated by `TestData.uses_clean_slate`,
          #   but before a savepoint is taken
          # config.after_test_data_truncate { }

          # Hook run after test data is truncated by `TestData.uses_rails_fixtures`,
          #   but before a savepoint is taken
          # config.after_rails_fixture_load { }

          # Tables whose data shouldn't be loaded into tests.
          #   ("ar_internal_metadata" and "schema_migrations" are always excluded)
          # config.non_test_data_tables = []

          # Tables whose data should be excluded from SQL dumps (still dumps their schema DDL)
          # config.dont_dump_these_tables = []

          # Where to store SQL dumps of the test_data database schema
          # config.schema_dump_path = "test/support/test_data/schema.sql"

          # Where to store SQL dumps of the test_data database test data
          # config.data_dump_path = "test/support/test_data/data.sql"

          # Where to store SQL dumps of the test_data database non-test data
          # config.non_test_data_dump_path = "test/support/test_data/non_test_data.sql"

          # Tables whose data should be truncated by TestData.uses_clean_slate
          #   If left as `nil`, all tables inserted into by the SQL file at
          #   `data_dump_path` will be truncated
          # config.truncate_these_test_data_tables = nil

          # Log level (valid values: [:debug, :info, :warn, :error, :quiet])
          #   Can also be set with env var TEST_DATA_LOG_LEVEL
          # config.log_level = :info
        end
      RUBY
    end
  end
end
