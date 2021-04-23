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
        name: "test data",
        database_name: @config.database_name,
        relative_path: @config.data_dump_path,
        full_path: @config.data_dump_full_path,
        flags: (@config.non_test_data_tables + @config.dont_dump_these_tables).uniq.map { |t| "-T #{t}" }.join(" ")
      )

      dump(
        type: :data,
        name: "non-test data",
        database_name: @config.database_name,
        relative_path: @config.non_test_data_dump_path,
        full_path: @config.non_test_data_dump_full_path,
        flags: (@config.non_test_data_tables - @config.dont_dump_these_tables).uniq.map { |t| "-t #{t}" }.join(" ")
      )
    end

    private

    def dump(type:, database_name:, relative_path:, full_path:, name: type, flags: "")
      dump_pathname = Pathname.new(full_path)
      FileUtils.mkdir_p(File.dirname(dump_pathname))
      command = "pg_dump #{database_name} --no-tablespaces --no-owner --inserts --#{type}-only #{flags} -f #{dump_pathname}"
      TestData.log.debug("Running #{type} SQL dump command:\n  #{command}")
      if system(command)
        TestData.log.info "Dumped database '#{database_name}' #{name} to '#{relative_path}'"
      else
        raise "Failed while attempting to  dump '#{database_name}' #{name} to '#{relative_path}'"
      end
    end
  end
end
