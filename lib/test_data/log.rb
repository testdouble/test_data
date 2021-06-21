module TestData
  def self.log
    @log ||= Log.new
  end

  class Log
    LEVELS = [:debug, :info, :warn, :error, :quiet]
    DEFAULT_WRITER = ->(message, level) do
      output = "[test_data:#{level}] #{message}"
      if [:warn, :error].include?(level)
        warn output
      else
        puts output
      end
    end
    PLAIN_WRITER = ->(message, level) do
      if [:warn, :error].include?(level)
        warn message
      else
        puts message
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
      self.level = ENV["TEST_DATA_LOG_LEVEL"]&.to_sym || :info
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

    def with_writer(writer, &blk)
      og_writer = self.writer
      self.writer = writer
      blk.call
      self.writer = og_writer
    end

    def with_plain_writer(&blk)
      with_writer(PLAIN_WRITER, &blk)
    end

    private

    def enabled?(level)
      LEVELS.index(level) >= LEVELS.index(@level)
    end
  end
end
