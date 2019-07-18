# frozen_string_literal: true

require "batchmaker/null_logger"

# rubocop:disable Metrics/ClassLength
class Batchmaker
  StoppedError = Class.new(StandardError)

  class << self
    attr_accessor :logger
  end

  # rubocop:disable Metrics/MethodLength
  def initialize(name, size, tick_period, on_error: nil, &block)
    @name     = name
    @size     = size
    @queue    = Queue.new
    @mutex    = Mutex.new
    @count    = 0
    @action   = block
    @on_error = on_error
    @stopping = false

    # Main thread that process the batches
    @thread = Thread.new(&method(:run))

    # Thread that ticks on a specified frequency
    @tick = Thread.new(tick_period, &method(:tick))
    @tick.abort_on_exception = true
    @tick.priority = 1
  end
  # rubocop:enable Metrics/MethodLength

  def running?
    %w[run sleep].include?(@thread.status) && !@stopping
  end

  def <<(item)
    raise StoppedError, "failure to queue item, #{ident_str} has already stopped" unless running?

    @mutex.synchronize do
      @queue << [:add, item]
      @count += 1

      if @count >= @size
        @count = 0
        @queue << %i[process size]
      end
    end

    Thread.pass
  end

  def shutdown!
    shutdown && wait
  end

  def shutdown
    info "shutting down"

    @mutex.synchronize do
      @stopping = true
      @queue << [:process]
      @queue << [:stop]
    end

    @tick.exit
  end

  def wait
    @thread.join
  end

  self.logger = NullLogger.new

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def run
    batch = []

    info "starting batch processing loop"
    loop do
      action, *args = @queue.pop

      case action
      when :add
        batch << args.first
        debug "item added to #{@name} batch: #{args.first.inspect}"

      when :process
        unless batch.empty?
          begin
            @action.(batch.freeze)
            debug "batch processed with #{batch.size} items"
          rescue StandardError => e
            error "batch with #{batch.size} failed to process due to '#{e.message}' - batch: #{batch.inspect}"
            @on_error&.call(e, ident_str)
            next
          ensure
            batch = []
          end
        end

      when :stop
        break
      end
    end

    info "exiting batch processing loop"
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def tick(period)
    loop do
      sleep(period)

      @mutex.synchronize do
        @queue << %i[process tick]
      end
    end
  end

  def ident_str
    "[#{self.class.name}(#{@name}):#{Process.pid}]"
  end

  def error(msg)
    logger.error "#{ident_str} error: #{msg}"
  end

  def info(msg)
    logger.info "#{ident_str} info: #{msg}"
  end

  def debug(msg)
    logger.debug "#{ident_str} debug: #{msg}"
  end

  def logger
    self.class.logger
  end
end
# rubocop:enable Metrics/ClassLength

require "batchmaker/railtie" if defined?(Rails)
