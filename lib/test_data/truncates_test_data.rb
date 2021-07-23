module TestData
  class TruncatesTestData
    def initialize
      @config = TestData.config
      @statistics = TestData.statistics
    end

    def call
      connection.disable_referential_integrity do
        connection.execute("TRUNCATE TABLE #{tables_to_truncate.map { |t| connection.quote_table_name(t) }.join(", ")} #{"CASCADE" unless @config.truncate_these_test_data_tables.present?}")
      end
      @statistics.count_truncate!
    end

    private

    def tables_to_truncate
      if @config.truncate_these_test_data_tables.present?
        @config.truncate_these_test_data_tables
      else
        @tables_to_truncate ||= IO.foreach(@config.data_dump_path).grep(/^INSERT INTO/) { |line|
          line.match(/^INSERT INTO ([^\s]+)/)&.captures&.first
        }.compact.uniq
      end
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
