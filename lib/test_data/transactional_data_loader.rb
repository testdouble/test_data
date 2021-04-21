require "fileutils"

module TestData
  def self.load
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.load
  end

  def self.rollback(save_point_name = :after_data_load)
    @transactional_data_loader ||= TransactionalDataLoader.new
    case save_point_name
    when :after_data_load
      @transactional_data_loader.rollback_to_after_data_load
    when :before_data_load
      @transactional_data_loader.rollback_to_before_data_load
    end
  end

  class TransactionalDataLoader
    def initialize
      @config = TestData.config
      @save_points = []
    end

    def load
      ensure_after_load_save_point_is_active_if_data_is_loaded!
      return if save_point_active?(:after_data_load)
      create_save_point(:before_data_load)
      execute_data_dump
      record_ar_internal_metadata_that_test_data_is_loaded
      create_save_point(:after_data_load)
    end

    def rollback_to_after_data_load
      rollback_save_point(:after_data_load)
      create_save_point(:after_data_load)
    end

    def rollback_to_before_data_load
      rollback_save_point(:before_data_load)
    end

    private

    def ensure_after_load_save_point_is_active_if_data_is_loaded!
      if !save_point_active?(:after_data_load) && ar_internal_metadata_shows_test_data_is_loaded?
        # "Test Data is loaded, but the after-data-load save point was rolled back. Recreating save point…"
        create_save_point(:after_data_load)
      end
    end

    def record_ar_internal_metadata_that_test_data_is_loaded
      if ar_internal_metadata_shows_test_data_is_loaded?
        warn "Attempted to record that test data is loaded in ar_internal_metadata, but record already existed. Perhaps a previous test run committed your test data?"
      else
        ActiveRecord::InternalMetadata.create!(key: "test_data:loaded", value: "true")
      end
    end

    def ar_internal_metadata_shows_test_data_is_loaded?
      ActiveRecord::InternalMetadata.find_by(key: "test_data:loaded")&.value == "true"
    end

    def execute_data_dump
      search_path = execute("show search_path").first["search_path"]
      execute(File.read(@config.data_dump_full_path))
      execute <<~SQL
        select pg_catalog.set_config('search_path', '#{search_path}', false)
      SQL
    end

    def save_point_active?(name)
      purge_closed_save_points!
      @save_points.find { |sp| sp.name == name }&.active?
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
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
