module TestData
  class SavePoint
    attr_reader :name, :transaction

    def initialize(name)
      @name = name
      @transaction = connection.begin_transaction(joinable: false, _lazy: false)
    end

    def active?
      !transaction.state.finalized?
    end

    def rollback!
      while active?
        connection.rollback_transaction
      end
    end

    private

    def connection
      ActiveRecord::Base.connection
    end
  end
end
