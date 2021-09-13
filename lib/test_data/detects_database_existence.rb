module TestData
  class DetectsDatabaseExistence
    def initialize
      @config = TestData.config
    end

    def call
      rows = ActiveRecord::Base.connection.execute <<~SQL
        select datname database_name
        from pg_catalog.pg_database
      SQL
      rows.any? { |row|
        row["database_name"] == @config.database_name
      }
    rescue ActiveRecord::NoDatabaseError
      false
    end
  end
end
