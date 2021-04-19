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
    SavePoint = Struct.new(:name, :transaction, keyword_init: true)

    def initialize
      @config = TestData.config
      @save_points = []
      @dump_count = 0
    end

    def load_data_dump
      create_save_point(:before_data_load) unless save_point?(:before_data_load)
      unless save_point?(:after_data_load)
        execute_data_dump
        @dump_count += 1
        create_save_point(:after_data_load)
      end
    end

    def rollback(to:)
      return unless save_point?(to)
      rollback_save_point(to)
    end

    private

    def execute_data_dump
      search_path = execute("show search_path").first["search_path"]
      execute(File.read(@config.data_dump_full_path))
      execute <<~SQL
        select pg_catalog.set_config('search_path', '#{search_path}', false)
      SQL
    end

    def save_point?(name)
      purge_closed_save_points!
      @save_points.any? { |sp| sp.name == name }
    end

    def create_save_point(name)
      save_point = SavePoint.new(
        name: name,
        transaction: ActiveRecord::Base.connection.begin_transaction(joinable: false, _lazy: false)
      )
      @save_points << save_point
    end

    def rollback_save_point(name)
      if (save_point = @save_points.find { |sp| sp.name == name }) && save_point.transaction.open?
        save_point.transaction.rollback
      end
      purge_closed_save_points!
    end

    def purge_closed_save_points!
      @save_points = @save_points.select { |save_point|
        save_point.transaction.open?
      }
    end

    def execute(sql)
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
