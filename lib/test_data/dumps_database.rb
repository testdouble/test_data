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
      before_size = File.size?(dump_pathname)
      if execute("pg_dump #{database_name} --no-tablespaces --no-owner --inserts --#{type}-only #{flags} -f #{dump_pathname}")
        prepend_set_replication_role!(full_path) if type == :data

        TestData.log.info "Dumped '#{database_name}' #{name} to '#{relative_path}'"
        log_size_info_and_warnings(before_size: before_size, after_size: File.size(dump_pathname))
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

    def log_size_info_and_warnings(before_size:, after_size:)
      percent_change = percent_change(before_size, after_size)
      TestData.log.info "  Size: #{to_size(after_size)}#{" (#{percent_change}% #{before_size > after_size ? "decrease" : "increase"})" if percent_change}"
      if after_size > 5242880
        TestData.log.warn "  WARNING: file size exceeds 5MB. Be sure to only persist what data you need to sufficiently test your application"
      end
      if before_size && (after_size - before_size) > 1048576
        TestData.log.warn "  WARNING: size of this dump increased by #{to_size(after_size - before_size)}. You may want to inspect the file to validate extraneous data was not committed"
      end
    end

    def percent_change(before_size, after_size)
      return unless before_size && before_size > 0 && after_size
      ((before_size - after_size).abs / before_size * 100).round(2)
    end

    def to_size(bytes)
      e = Math.log10(bytes).to_i / 3
      "%.0f" % (bytes / 1000**e) + [" bytes", "KB", "MB", "GB"][e]
    end
  end
end
