require "fileutils"

module TestData
  def self.load_data_dump
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.load_data_dump
  end

  def self.rollback
    raise Error.new("rollback called before load_data_dump") unless @transactional_data_loader.present?
    @transactional_data_loader.rollback_between_tests
  end

  def self.reset
    @transactional_data_loader&.reset
  end

  class TransactionalDataLoader
    def initialize
      @config = TestData.config
      @save_points = []
    end

    def load_data_dump
      return if save_point_active?(:after_data_load)
      create_save_point(:before_data_load) unless save_point_active?(:before_data_load)
      execute_data_dump
      create_save_point(:after_data_load)
    end

    def rollback_between_tests
      rollback_save_point(:after_data_load)
      create_save_point(:after_data_load)
    end

    def reset
      rollback_save_point(:before_data_load)
    end

    private

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
