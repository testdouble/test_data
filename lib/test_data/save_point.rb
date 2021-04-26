module TestData
  class SavePoint
    attr_reader :name, :transaction

    def initialize(name)
      @name = name
      @transaction = connection.begin_transaction(joinable: false, _lazy: false)
    end

    def active?
      !@transaction.state.finalized?
    end

    def rollback!
      warn_if_not_rollbackable!
      while active?
        connection.rollback_transaction
      end
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def warn_if_not_rollbackable!
      return if active?
      TestData.log.warn(
        "Attempted to roll back transaction save point '#{name}', but its state was #{@transaction.state}"
      )
    end
  end
end
