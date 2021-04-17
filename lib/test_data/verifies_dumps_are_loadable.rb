module TestData
  class VerifiesDumpsAreLoadable
    def initialize
      @config = TestData.config
      @detects_database_emptiness = DetectsDatabaseEmptiness.new
    end

    def call
      schema_dump_looks_good = Pathname.new(@config.schema_dump_full_path).readable?
      if !schema_dump_looks_good
        warn "Warning: Database schema dump '#{@config.schema_dump_path}' not readable"
      end

      data_dump_looks_good = Pathname.new(@config.data_dump_full_path).readable?
      if !data_dump_looks_good
        warn "Warning: Database data dump '#{@config.data_dump_path}' not readable"
      end

      database_empty = @detects_database_emptiness.empty?
      unless database_empty
        warn "Warning: Database '#{@config.database_name}' is not empty"
      end

      [schema_dump_looks_good, data_dump_looks_good, database_empty].all?
    end
  end
end
