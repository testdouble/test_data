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
      while active?
        __debug("pre-rollback")
        __print_transactions
        connection.rollback_transaction
        __debug("post-rollback")
        __print_transactions
      end
    end

    private

    def connection
      ActiveRecord::Base.connection
    end

    def __debug(s = "")
      puts "DEBUG SP #{name}: #{s} | #{ActiveRecord::Base.connection.instance_variable_get("@config")[:database]} | Boops: #{Boop.count} | Active: #{active?}"
    end

    def __transactions
      ActiveRecord::Base.connection.transaction_manager.instance_variable_get("@stack").map { |t|
        {
          id: t.state.object_id,
          save_point: ("it me! #{@name}" if @transaction.state.equal?(t.state)),
          children: t.state.instance_variable_get("@children")&.map(&:object_id),
          final: t.state.finalized?
        }
      }
    end

    def __print_transactions
      s = "  transactions:\n"
      __transactions.each do |t|
        t.each do |k, v|
          s += "    #{k}: #{v}\n"
        end
      end
      puts s
    end
  end
end
