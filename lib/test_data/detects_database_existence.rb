module TestData
  class DetectsDatabaseExistence
    def call
      ActiveRecord::Base.connection.execute("select 1")
      true
    rescue ActiveRecord::NoDatabaseError
      false
    end
  end
end
