module TestData
  class InsertsTestData
    def initialize
      @config = TestData.config
      @statistics = TestData.statistics
    end

    def call
      search_path = connection.execute("show search_path").first["search_path"]
      connection.disable_referential_integrity do
        connection.execute(File.read(@config.data_dump_full_path))
      end
      connection.execute <<~SQL
        select pg_catalog.set_config('search_path', '#{search_path}', false)
      SQL
      @statistics.count_load!
    end

    private

    def connection
      ActiveRecord::Base.connection
    end
  end
end
