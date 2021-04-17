module TestData
  class DetectsDatabaseEmptiness
    def initialize
      @config = TestData.config
    end

    def empty?
      result = ActiveRecord::Base.connection.execute <<~SQL
        select not exists (
          select from information_schema.tables
          where table_name = 'ar_internal_metadata'
        ) as empty
      SQL
      result.first["empty"]
    end
  end
end
