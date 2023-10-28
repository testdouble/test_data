module TestData
  class RecordsDumpMetadata
    def call
      TestData.create_metadata!(key: "test_data:last_dumped_at", value: Time.now.utc.inspect)
    end
  end
end
