require "rails/generators"

module TestData
  class EnvironmentFileGenerator < Rails::Generators::Base
    def call
      create_file "config/environments/test_data.rb", <<~RUBY
        require_relative "development"

        Rails.application.configure do
          config.active_record.dump_schema_after_migration = false
        end
      RUBY
    end
  end
end
