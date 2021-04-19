require "fileutils"

module TestData
  def self.load_data_dump
    @transactional_data_loader ||= TransactionalDataLoader.new
    @transactional_data_loader.load_data_dump
  end

  def self.rollback(to: :after_data_load)
    raise Error.new("rollback called before load_data_dump") unless @transactional_data_loader.present?
    @transactional_data_loader.rollback(to: to)
  end

  class TransactionalDataLoader
    def initialize
      @config = TestData.config
      @save_points = []
    end

    def load_data_dump
      create_transaction_if_necessary
      create_save_point(:before_data_load) if save_point?(:before_data_load)
      unless save_point?(:after_data_load)
        execute_data_dump
        create_save_point(:after_data_load)
      end
    end

    def rollback(to:)
      return unless save_point?(to)
      rollback_save_point(to)
    end

    private

    def reset_save_point_memory
      @save_points = []
    end

    def create_transaction_if_necessary
      return if ActiveRecord::Base.connection.transaction_open?
      reset_save_point_memory
      ActiveRecord::Base.connection.begin_transaction(joinable: false, _lazy: false)
    end

    def execute_data_dump
      search_path = execute("show search_path").first["search_path"]
      execute(File.read(@config.data_dump_full_path))
      execute <<~SQL
        select pg_catalog.set_config('search_path', '#{search_path}', false)
      SQL
    end

    def save_point?(name)
      if ActiveRecord::Base.connection.transaction_open?
        @save_points.include?(name)
      else
        reset_save_point_memory
      end
    end

    def create_save_point(name)
      execute("savepoint __test_data_gem_#{name}")
      @save_points << name
    end

    def rollback_save_point(name)
      execute("rollback to savepoint __test_data_gem_#{name}")
      @save_points = @save_points.take(@save_points.index(name) + 1)
    end

    def execute(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
