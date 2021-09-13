module TestData
  class DeterminesWhenSqlDumpWasMade
    def initialize
      @config = TestData.config
    end

    def call
      if (last_dumped_at = find_last_dumped_value)
        Time.zone.parse(last_dumped_at)
      end
    end

    private

    def find_last_dumped_value
      return unless File.exist?(@config.non_test_data_dump_path)
      File.open(@config.non_test_data_dump_path, "r").each_line do |line|
        if (match = line.match(/INSERT INTO public\.ar_internal_metadata VALUES \('test_data:last_dumped_at', '([^']*)'/))
          return match[1]
        end
      end
    end
  end
end
