module TestData
  def self.log
    @log ||= Log.new
  end

  class Log
    LEVELS = [:debug, :info, :warn, :error, :quiet]
    DEFAULT_WRITER = ->(message, level) do
      output = "[test_data: #{level}] #{message}"
      if [:warn, :error].include?(level)
        warn output
      else
        puts output
      end
    end

    attr_reader :level, :writer

    def initialize
      reset
    end

    LEVELS[0...4].each do |level|
      define_method level.to_s do |message|
        next unless message.strip.present?

        @writer.call(message, level) if enabled?(level)
      end
    end

    def reset
      @level = :info
      @writer = DEFAULT_WRITER
    end

    def level=(level)
      if LEVELS.include?(level)
        @level = level
      else
        raise Error.new("Not a valid level")
      end
    end

    def writer=(writer)
      if writer.respond_to?(:call)
        @writer = writer
      else
        raise Error.new("Log writer must be callable")
      end
    end

    private

    def enabled?(level)
      LEVELS.index(level) >= LEVELS.index(@level)
    end
  end
end
