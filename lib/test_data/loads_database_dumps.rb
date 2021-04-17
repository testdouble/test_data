require "pathname"
require "fileutils"

module TestData
  class LoadsDatabaseDumps
    def initialize
      @config = TestData.config
    end

    def call
      load_dump(
        type: :schema,
        database_name: @config.database_name,
        relative_path: @config.schema_dump_path,
        full_path: @config.schema_dump_full_path
      )

      load_dump(
        type: :data,
        database_name: @config.database_name,
        relative_path: @config.data_dump_path,
        full_path: @config.data_dump_full_path
      )
    end

    private

    def load_dump(type:, database_name:, relative_path:, full_path:)
      dump_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p(File.dirname(dump_pathname))
      if system "psql -q -d #{database_name} < #{dump_pathname}"
        puts "Loaded #{type} from '#{relative_path}' into database '#{database_name}' "
      else
        raise "Failed while attempting to load #{type} from '#{relative_path}' into database '#{database_name}'"
      end
    end
  end
end
