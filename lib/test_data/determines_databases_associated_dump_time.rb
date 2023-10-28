module TestData
  class DeterminesDatabasesAssociatedDumpTime
    def call
      if (last_dumped_at = TestData.find_metadata(key: "test_data:last_dumped_at").presence)
        Time.parse(last_dumped_at)
      end
    rescue ActiveRecord::StatementInvalid
      # This will be raised if the DB exists but hasn't been migrated/schema-loaded
    rescue ActiveRecord::NoDatabaseError
      # This will be raised if the DB doesn't exist yet, which we don't need to warn about
    end
  end
end
