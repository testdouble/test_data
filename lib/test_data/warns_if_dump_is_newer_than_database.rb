module TestData
  class WarnsIfDumpIsNewerThanDatabase
    def initialize
      @config = TestData.config
      @determines_when_sql_dump_was_made = DeterminesWhenSqlDumpWasMade.new
      @determines_databases_associated_dump_time = DeterminesDatabasesAssociatedDumpTime.new
    end

    def call
      return unless Rails.env.test_data?
      sql_dumped_at = @determines_when_sql_dump_was_made.call
      database_dumped_at = @determines_databases_associated_dump_time.call

      if sql_dumped_at.present? &&
          database_dumped_at.present? &&
          sql_dumped_at > database_dumped_at
        TestData.log.warn <<~MSG
          The SQL dumps in '#{File.dirname(@config.data_dump_path)}' were created
          after your local test_data database '#{@config.database_name}' was last dumped.

            SQL Dump: #{sql_dumped_at.localtime}
            Database: #{database_dumped_at.localtime}

          To avoid potential data loss, you may want to consider dropping '#{@config.database_name}'
          and loading the SQL dumps before making changes to the test data in this database
          or performing another dump.

          To do this, kill any processes with RAILS_ENV=test_data and then run:

            $ bin/rake test_data:reinitialize

        MSG
      end
    end
  end
end
