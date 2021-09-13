module TestData
  class RecordsDumpMetadata
    def call
      ActiveRecord::InternalMetadata
        .find_or_initialize_by(key: "test_data:last_dumped_at")
        .update!(value: Time.now.utc.inspect)
    end
  end
end
