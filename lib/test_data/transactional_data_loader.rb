module TestData
  def self.uninitialize
    @data_loader ||= TransactionalDataLoader.new
    @data_loader.rollback_to_before_data_load
  end

  def self.uses_test_data
    @data_loader ||= TransactionalDataLoader.new
    @data_loader.load
  end

  def self.uses_clean_slate
    @data_loader ||= TransactionalDataLoader.new
    @data_loader.truncate
  end

  def self.uses_rails_fixtures(test_instance)
    if !test_instance.respond_to?(:setup_fixtures)
      raise Error.new("'TestData.uses_rails_fixtures(self)' must be passed a test instance that has had ActiveRecord::TestFixtures mixed-in (e.g. `TestData.uses_rails_fixtures(self)` in an ActiveSupport::TestCase `setup` block), but the provided argument does not respond to 'setup_fixtures'")
    elsif !test_instance.respond_to?(:__test_data_gem_setup_fixtures)
      raise Error.new("'TestData.uses_rails_fixtures(self)' depends on Rails' default fixture-loading behavior being disabled by calling 'TestData.prevent_rails_fixtures_from_loading_automatically!' as early as possible (e.g. near the top of your test_helper.rb), but it looks like it was never called.")
    end
    @data_loader ||= TransactionalDataLoader.new
    @data_loader.load_rails_fixtures(test_instance)
  end

  def self.insert_test_data_dump
    InsertsTestDataDump.new.call
  end

  class InsertsTestDataDump
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

  class TransactionalDataLoader
    def initialize
      @inserts_test_data_dump = InsertsTestDataDump.new
      @config = TestData.config
      @statistics = TestData.statistics
      @save_points = []
      @already_loaded_rails_fixtures = {}
    end

    def load
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      return rollback_to_after_data_load if save_point_active?(:after_data_load)

      create_save_point(:before_data_load)
      @inserts_test_data_dump.call
      record_ar_internal_metadata_that_test_data_is_loaded
      create_save_point(:after_data_load)
    end

    def rollback_to_before_data_load
      if save_point_active?(:before_data_load)
        rollback_save_point(:before_data_load)
        # No need to recreate the save point -- TestData.uses_test_data will if called
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

    def rollback_to_after_load_rails_fixtures
      if save_point_active?(:after_load_rails_fixtures)
        rollback_save_point(:after_load_rails_fixtures)
        create_save_point(:after_load_rails_fixtures)
      end
    end

    def truncate
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
        TestData.log.debug("TestData.uses_clean_slate was called, but data was not loaded. Loading data before truncate to preserve the transaction save point ordering")
        load
      end

      execute_data_truncate
      record_ar_internal_metadata_that_test_data_is_truncated
      create_save_point(:after_data_truncate)
    end

    # logic is beat-for-beat the same as #truncate just one step deeper down
    # this rabbit hole…
    def load_rails_fixtures(test_instance)
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      ensure_after_truncate_save_point_is_active_if_data_is_truncated!
      ensure_after_load_rails_fixtures_save_point_is_active_if_fixtures_are_loaded!
      reset_rails_fixture_caches(test_instance)
      return rollback_to_after_load_rails_fixtures if save_point_active?(:after_load_rails_fixtures) && @already_loaded_rails_fixtures[test_instance.class].present?

      if save_point_active?(:after_data_truncate)
        rollback_to_after_data_truncate
      else
        truncate
      end

      execute_load_rails_fixtures(test_instance)
      record_ar_internal_metadata_that_rails_fixtures_are_loaded
      create_save_point(:after_load_rails_fixtures)
    end

    private

    def execute_data_truncate
      connection.disable_referential_integrity do
        connection.execute("TRUNCATE TABLE #{tables_to_truncate.map { |t| connection.quote_table_name(t) }.join(", ")} #{"CASCADE" unless @config.truncate_these_test_data_tables.present?}")
      end
      @statistics.count_truncate!
    end

    def execute_load_rails_fixtures(test_instance)
      test_instance.pre_loaded_fixtures = false
      test_instance.use_transactional_tests = false
      test_instance.__test_data_gem_setup_fixtures
      @already_loaded_rails_fixtures[test_instance.class] = test_instance.instance_variable_get(:@loaded_fixtures)
      @statistics.count_load_rails_fixtures!
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

    def connection
      ActiveRecord::Base.connection
    end

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

    def ensure_after_load_rails_fixtures_save_point_is_active_if_fixtures_are_loaded!
      if !save_point_active?(:after_load_rails_fixtures) && ar_internal_metadata_shows_rails_fixtures_are_loaded?
        TestData.log.debug "Rails Fixtures appears to have been loaded by test_data, but the :after_load_rails_fixtures save point was rolled back (and not by this gem). Recreating the :after_load_rails_fixtures save point"
        create_save_point(:after_load_rails_fixtures)
      end
    end

    def record_ar_internal_metadata_that_rails_fixtures_are_loaded
      if ar_internal_metadata_shows_rails_fixtures_are_loaded?
        TestData.log.warn "Attempted to record that test_data had loaded your Rails fixtures in ar_internal_metadata, but record already existed. Perhaps a previous test run committed the loading of your Rails fixtures?"
      else
        ActiveRecord::InternalMetadata.create!(key: "test_data:rails_fixtures_loaded", value: "true")
      end
    end

    def ar_internal_metadata_shows_rails_fixtures_are_loaded?
      ActiveRecord::InternalMetadata.find_by(key: "test_data:rails_fixtures_loaded")&.value == "true"
    end

    def reset_rails_fixture_caches(test_instance)
      ActiveRecord::FixtureSet.reset_cache
      test_instance.instance_variable_set(:@loaded_fixtures, @already_loaded_rails_fixtures[test_instance.class])
      test_instance.instance_variable_set(:@fixture_cache, {})
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
  end
end
