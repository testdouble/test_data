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
    @rails_fixtures_loader ||= CustomLoaders::RailsFixtures.new
    @data_loader ||= TransactionalDataLoader.new
    @data_loader.load_custom_data(@rails_fixtures_loader, test_instance: test_instance)
  end

  def self.insert_test_data_dump
    InsertsTestData.new.call
  end

  class TransactionalDataLoader
    def initialize
      @inserts_test_data = InsertsTestData.new
      @truncates_test_data = TruncatesTestData.new
      @config = TestData.config
      @statistics = TestData.statistics
      @save_points = []
    end

    def load
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      return rollback_to_after_data_load if save_point_active?(:after_data_load)

      create_save_point(:before_data_load)
      @inserts_test_data.call
      record_ar_internal_metadata_that_test_data_is_loaded
      create_save_point(:after_data_load)
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

      @truncates_test_data.call
      record_ar_internal_metadata_that_test_data_is_truncated
      create_save_point(:after_data_truncate)
    end

    def load_custom_data(loader, **options)
      loader.validate!(**options)
      snapshot_name = "user_#{loader.name}".to_sym

      ensure_after_load_save_point_is_active_if_data_is_loaded!
      ensure_after_truncate_save_point_is_active_if_data_is_truncated!
      ensure_custom_save_point_is_active_if_memo_exists!(snapshot_name)

      loader.load_requested(**options)
      if save_point_active?(snapshot_name) && loader.loaded?(**options)
        return rollback_to_custom_savepoint(snapshot_name)
      end

      if save_point_active?(:after_data_truncate)
        rollback_to_after_data_truncate
      else
        truncate
      end

      loader.load(**options)
      record_ar_internal_metadata_of_custom_save_point(snapshot_name)
      create_save_point(snapshot_name)
    end

    def rollback_to_before_data_load
      if save_point_active?(:before_data_load)
        rollback_save_point(:before_data_load)
        # No need to recreate the save point
        # (TestData.uses_test_data will if called)
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

    def rollback_to_custom_savepoint(name)
      if save_point_active?(name)
        rollback_save_point(name)
        create_save_point(name)
      end
    end

    private

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

    def ensure_custom_save_point_is_active_if_memo_exists!(name)
      if !save_point_active?(name) && ar_internal_metadata_shows_custom_operation_was_persisted?(name)
        TestData.log.debug "#{name} appears to have been loaded by test_data, but the #{name} save point was rolled back (and not by this gem). Recreating the #{name} save point"
        create_save_point(name)
      end
    end

    def ar_internal_metadata_shows_custom_operation_was_persisted?(name)
      ActiveRecord::InternalMetadata.find_by(key: "test_data:#{name}")&.value == "true"
    end

    def record_ar_internal_metadata_of_custom_save_point(name)
      if ar_internal_metadata_shows_custom_operation_was_persisted?(name)
        TestData.log.warn "Attempted to record that test_data had loaded #{name} in ar_internal_metadata, but record already existed. Perhaps a previous test run committed it?"
      else
        ActiveRecord::InternalMetadata.create!(key: "test_data:#{name}", value: "true")
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
  end
end
