module TestData
  class DeterminesDatabasesAssociatedDumpTime
    def call
      internal_metadata = ActiveRecord::InternalMetadata.new(ActiveRecord::Base.connection)
      if (last_dumped_at = internal_metadata["test_data:last_dumped_at"])
        Time.parse(last_dumped_at)
      end
    rescue ActiveRecord::StatementInvalid
      # This will be raised if the DB exists but hasn't been migrated/schema-loaded
    rescue ActiveRecord::NoDatabaseError
      # This will be raised if the DB doesn't exist yet, which we don't need to warn about
    end
  end
end
