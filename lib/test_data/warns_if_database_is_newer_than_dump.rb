module TestData
  class WarnsIfDatabaseIsNewerThanDump
    def initialize
      @config = TestData.config
      @determines_when_sql_dump_was_made = DeterminesWhenSqlDumpWasMade.new
      @determines_databases_associated_dump_time = DeterminesDatabasesAssociatedDumpTime.new
    end

    def call
      return unless Rails.env.test_data?
      sql_dumped_at = @determines_when_sql_dump_was_made.call
      database_dumped_at = @determines_databases_associated_dump_time.call

      if database_dumped_at.present? &&
          sql_dumped_at.present? &&
          database_dumped_at > sql_dumped_at
        TestData.log.warn <<~MSG
          Your local test_data database '#{@config.database_name}' is associated
          with a SQL dump that was NEWER than the current dumps located in
          '#{File.dirname(@config.data_dump_path)}':

            SQL Dump: #{sql_dumped_at.localtime}
            Database: #{database_dumped_at.localtime}

          If you're not intentionally resetting your local test_data database to an earlier
          version, you may want to take a closer look before taking any destructive actions.

        MSG
      end
    end
  end
end
