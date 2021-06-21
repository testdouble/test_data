module TestData
  def self.config(pwd: Rails.root, &blk)
    @configuration ||= Configuration.new(pwd: pwd)

    @configuration.tap do |config|
      blk&.call(config)
    end
  end

  class Configuration
    # Where to save dumps of your test data's schema
    attr_accessor :schema_dump_path

    # Where to save dumps of your test data
    attr_accessor :data_dump_path

    # Where to save dumps of data needed by the test_data env but excluded from your tests
    attr_accessor :non_test_data_dump_path

    # Tables to exclude from test data dumps
    attr_writer :non_test_data_tables
    def non_test_data_tables
      (@non_test_data_tables + [
        ActiveRecord::Base.connection.schema_migration.table_name,
        ActiveRecord::InternalMetadata.table_name
      ]).uniq
    end

    # Tables to exclude from all dumps
    attr_accessor :dont_dump_these_tables

    # Tables to truncate when TestData.truncate is called
    attr_accessor :truncate_these_test_data_tables

    # Log level (valid values: [:debug, :info, :warn, :error, :quiet])
    def log_level
      TestData.log.level
    end

    def log_level=(level)
      TestData.log.level = level
    end

    attr_reader :pwd, :cable_yaml_path, :database_yaml_path, :secrets_yaml_path

    def self.full_path_reader(*relative_path_readers)
      relative_path_readers.each do |relative_path_reader|
        define_method(relative_path_reader.to_s.gsub(/_path$/, "_full_path")) do
          "#{pwd}/#{send(relative_path_reader)}"
        end
      end
    end

    full_path_reader :schema_dump_path, :data_dump_path, :non_test_data_dump_path, :cable_yaml_path, :database_yaml_path, :secrets_yaml_path

    def initialize(pwd:)
      @pwd = pwd
      @schema_dump_path = "test/support/test_data/schema.sql"
      @data_dump_path = "test/support/test_data/data.sql"
      @non_test_data_dump_path = "test/support/test_data/non_test_data.sql"
      @cable_yaml_path = "config/cable.yml"
      @database_yaml_path = "config/database.yml"
      @secrets_yaml_path = "config/secrets.yml"
      @non_test_data_tables = []
      @dont_dump_these_tables = []
      @truncate_these_test_data_tables = nil
    end

    def database_yaml
      YAML.load_file(database_yaml_full_path)
    end

    def database_name
      database_yaml.dig("test_data", "database")
    end
  end
end
