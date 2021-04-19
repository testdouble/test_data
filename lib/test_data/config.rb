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

    attr_reader :pwd, :database_yaml_path

    def self.full_path_reader(*relative_path_readers)
      relative_path_readers.each do |relative_path_reader|
        define_method(relative_path_reader.to_s.gsub(/_path$/, "_full_path")) do
          "#{pwd}/#{send(relative_path_reader)}"
        end
      end
    end

    full_path_reader :data_dump_path, :schema_dump_path, :database_yaml_path

    def initialize(pwd:)
      @pwd = pwd
      @schema_dump_path = "test/support/test_data/schema.sql"
      @data_dump_path = "test/support/test_data/data.sql"
      @database_yaml_path = "config/database.yml"
    end

    def database_yaml
      YAML.load_file(database_yaml_full_path)
    end

    def database_name
      database_yaml.dig("test_data", "database")
    end
  end
end
