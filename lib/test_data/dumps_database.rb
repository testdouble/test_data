require "pathname"
require "fileutils"

module TestData
  class DumpsDatabase
    def initialize
      @config = TestData.config
    end

    def call
      dump(
        type: :schema,
        database_name: @config.database_name,
        relative_path: @config.schema_dump_path,
        full_path: @config.schema_dump_full_path
      )

      dump(
        type: :data,
        database_name: @config.database_name,
        relative_path: @config.data_dump_path,
        full_path: @config.data_dump_full_path
      )
    end

    private

    def dump(type:, database_name:, relative_path:, full_path:)
      dump_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p(File.dirname(dump_pathname))
      if system "pg_dump #{database_name} --no-tablespaces --no-owner --#{type}-only -f #{dump_pathname}"
        puts "Dumped database '#{database_name}' #{type} to '#{relative_path}'"
      else
        raise "Failed while attempting to  dump '#{database_name}' #{type} to '#{relative_path}'"
      end
    end
  end
end
