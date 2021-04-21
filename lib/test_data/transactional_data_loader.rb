require "fileutils"

module TestData
  def self.load
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.load
  end

  def self.rollback(to: :after_data_load)
    @transactional_data_loader ||= TransactionalDataLoader.new
    case to
    when :after_data_load then @transactional_data_loader.rollback_to_after_data_load
    when :before_data_load then @transactional_data_loader.rollback_to_before_data_load
    end
  end

  class TransactionalDataLoader
    def initialize
      @config = TestData.config
      @save_points = []
    end

    def load
      return if save_point_active?(:after_data_load)
      create_save_point(:before_data_load) unless save_point_active?(:before_data_load)
      execute_data_dump
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
