require "rails/generators"

module TestData
  class EnvironmentFileGenerator < Rails::Generators::Base
    def call
      create_file "config/environments/test_data.rb", <<~RUBY
        require_relative "development"

        TestData.config do |config|
          # Where to save and load schema SQL dumps of the test_data database
          # config.schema_dump_path = "test/support/test_data/schema.sql"
          
          # Where to save and load data SQL dumps of the test_data database
          # config.data_dump_path = "test/support/test_data/data.sql"
        end

        Rails.application.configure do
          config.active_record.dump_schema_after_migration = false
        end
      RUBY
    end
  end
end
