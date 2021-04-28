module TestData
  def self.load(transactions: true)
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.load(transactions: transactions)
  end

  def self.rollback(save_point_name = :after_data_load)
    @transactional_data_loader ||= TransactionalDataLoader.new
    case save_point_name
    when :before_data_load
      @transactional_data_loader.rollback_to_before_data_load
    when :after_data_load
      @transactional_data_loader.rollback_to_after_data_load
    when :after_data_truncate
      @transactional_data_loader.rollback_to_after_data_truncate
    else
      raise Error.new("No known save point named '#{save_point_name}'. Valid values are: [:before_data_load, :after_data_load, :after_data_truncate]")
    end
  end

  def self.truncate(transactions: true)
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.truncate(transactions: transactions)
  end

  class TransactionalDataLoader
    def initialize
      @config = TestData.config
      @statistics = TestData.statistics
      @save_points = []
    end

    def load(transactions: true)
      return execute_data_dump unless transactions
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      return rollback_to_after_data_load if save_point_active?(:after_data_load)

      create_save_point(:before_data_load)
      execute_data_dump
      record_ar_internal_metadata_that_test_data_is_loaded
      create_save_point(:after_data_load)
    end

    def rollback_to_before_data_load
      if save_point_active?(:before_data_load)
        rollback_save_point(:before_data_load)
        # No need to recreate the save point -- TestData.load will if called
      end
    end

    def rollback_to_after_data_load
      if save_point_active?(:after_data_load)
        rollback_save_point(:after_data_load)
        create_save_point(:after_data_load)
      end
    end

    def rollback_to_after_data_truncate
      if save_point_active?(:after_data_truncate)
        rollback_save_point(:after_data_truncate)
        create_save_point(:after_data_truncate)
      end
    end

    def truncate(transactions: true)
      return execute_data_truncate unless transactions
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      ensure_after_truncate_save_point_is_active_if_data_is_truncated!
      return rollback_to_after_data_truncate if save_point_active?(:after_data_truncate)

      if save_point_active?(:after_data_load)
        # If a test that uses the test data runs before a test that starts by
        # calling truncate, tables in the database that would NOT be truncated
        # may have been changed. To avoid this category of test pollution, start
        # the truncation by rolling back to the known clean point
        rollback_to_after_data_load
      else
        # Seems silly loading data when the user asked us to truncate, but
        # it's important that the state of the transaction stack matches the
        # mental model we advertise, because any _other_ test in their suite
        # should expect that the existence of :after_data_truncate save point
        # implies that it's safe to rollback to the :after_data_load save
        # point; since tests run in random order, it's likely to happen
        TestData.log.warn("TestData.truncate was called, but data was not loaded. Loading data before truncate to preserve the documents transaction save point ordering")
        load(transactions: true)
      end

      execute_data_truncate
      record_ar_internal_metadata_that_test_data_is_truncated
      create_save_point(:after_data_truncate)
    end

    private

    def ensure_after_load_save_point_is_active_if_data_is_loaded!
      if !save_point_active?(:after_data_load) && ar_internal_metadata_shows_test_data_is_loaded?
        TestData.log.debug "Test data appears to be loaded, but the :after_data_load save point was rolled back (and not by this gem). Recreating the :after_data_load save point"
        create_save_point(:after_data_load)
      end
    end

    def record_ar_internal_metadata_that_test_data_is_loaded
      if ar_internal_metadata_shows_test_data_is_loaded?
        TestData.log.warn "Attempted to record that test data is loaded in ar_internal_metadata, but record already existed. Perhaps a previous test run committed your test data?"
      else
        ActiveRecord::InternalMetadata.create!(key: "test_data:loaded", value: "true")
      end
    end

    def ar_internal_metadata_shows_test_data_is_loaded?
      ActiveRecord::InternalMetadata.find_by(key: "test_data:loaded")&.value == "true"
    end

    def ensure_after_truncate_save_point_is_active_if_data_is_truncated!
      if !save_point_active?(:after_data_truncate) && ar_internal_metadata_shows_test_data_is_truncated?
        TestData.log.debug "Test data appears to be loaded, but the :after_data_truncate save point was rolled back (and not by this gem). Recreating the :after_data_truncate save point"
        create_save_point(:after_data_truncate)
      end
    end

    def record_ar_internal_metadata_that_test_data_is_truncated
      if ar_internal_metadata_shows_test_data_is_truncated?
        TestData.log.warn "Attempted to record that test data is truncated in ar_internal_metadata, but record already existed. Perhaps a previous test run committed the truncation of your test data?"
      else
        ActiveRecord::InternalMetadata.create!(key: "test_data:truncated", value: "true")
      end
    end

    def ar_internal_metadata_shows_test_data_is_truncated?
      ActiveRecord::InternalMetadata.find_by(key: "test_data:truncated")&.value == "true"
    end

    def execute_data_dump
      search_path = execute("show search_path").first["search_path"]
      connection.disable_referential_integrity do
        execute(File.read(@config.data_dump_full_path))
      end
      execute <<~SQL
        select pg_catalog.set_config('search_path', '#{search_path}', false)
      SQL
      @statistics.count_load!
    end

    def execute_data_truncate
      connection.disable_referential_integrity do
        execute("TRUNCATE TABLE #{tables_to_truncate.map { |t| connection.quote_table_name(t) }.join(", ")}")
      end
      @statistics.count_truncate!
    end

    def tables_to_truncate
      if @config.truncate_these_test_data_tables.present?
        @config.truncate_these_test_data_tables
      else
        @tables_to_truncate ||= IO.foreach(@config.data_dump_path).grep(/^INSERT INTO/) { |line|
          line.match(/^INSERT INTO ([^\s]+)/)&.captures&.first
        }.compact.uniq
      end
    end

    def save_point_active?(name)
      purge_closed_save_points!
      !!@save_points.find { |sp| sp.name == name }&.active?
    end

    def create_save_point(name)
      raise Error.new("Could not create test_data savepoint '#{name}', because it was already active!") if save_point_active?(name)
      @save_points << SavePoint.new(name)
    end

    def rollback_save_point(name)
      @save_points.find { |sp| sp.name == name }&.rollback!
      purge_closed_save_points!
    end

    def purge_closed_save_points!
      @save_points = @save_points.select { |save_point|
        save_point.active?
      }
    end

    def execute(sql)
      connection.execute(sql)
    end

    def connection
      ActiveRecord::Base.connection
    end
  end
end
