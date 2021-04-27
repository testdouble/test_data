require "pathname"
require "fileutils"
require "open3"

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
        flags: (@config.non_test_data_tables + @config.dont_dump_these_tables).uniq.map { |t| "-T #{t} -T #{t}_id_seq" }.join(" ")
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
      if execute("pg_dump #{database_name} --no-tablespaces --no-owner --inserts --#{type}-only #{flags} -f #{dump_pathname}")
        prepend_set_replication_role!(full_path) if type == :data

        TestData.log.info "Dumped '#{database_name}' #{name} to '#{relative_path}'"
      else
        raise "Failed while attempting to  dump '#{database_name}' #{name} to '#{relative_path}'"
      end
    end

    def execute(command)
      TestData.log.debug("Running SQL dump command:\n  #{command}")
      stdout, stderr, status = Open3.capture3(command)
      if status == 0
        TestData.log.debug(stdout)
        TestData.log.debug(stderr)
        true
      else
        TestData.log.info(stdout)
        TestData.log.error(stderr)
        false
      end
    end

    def prepend_set_replication_role!(data_dump_path)
      system <<~COMMAND
        ed -s #{data_dump_path} <<EOF
        1 s/^/set session_replication_role = replica;/
        w
        EOF
      COMMAND
      TestData.log.debug("Prepended replication role instruction to '#{data_dump_path}'")
    end
  end
end
