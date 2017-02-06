require 'batcher/null_logger'

class Batcher
  VERSION = '0.1.1'
  StoppedError = Class.new(StandardError)

  def initialize(name, size, tick_period, on_error: nil, &block)
    @name     = name
    @size     = size
    @queue    = Queue.new
    @mutex    = Mutex.new
    @count    = 0
    @action   = block
    @on_error = on_error
    @stopping  = false

    # Main thread that process the batches
    @thread = Thread.new(&method(:run))

    # Thread that ticks on a specified frequency
    @tick = Thread.new(tick_period, &method(:tick))
    @tick.abort_on_exception = true
    @tick.priority = 1
  end

  def running?
    ["run", "sleep"].include?(@thread.status) && !@stopping
  end

  def <<(item)
    if !running?
      raise StoppedError, "failure to queue item, #{ident_str} has already stopped"
    end

    @mutex.synchronize do
      @queue << [:add, item]
      @count += 1

      if @count >= @size
        @count = 0
        @queue << [:process, :size]
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

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  private

  def run
    batch = []

    info "starting batch processing loop"
    loop do
      action, *args = @queue.pop

      case action
      when :add
        batch << args.first
        info "item added to #{@name} batch: #{args.first.inspect}"

      when :process
        unless batch.empty?
          begin
            @action.(batch.freeze)
            info "batch processed with #{batch.size} items"
          rescue => e
            error "batch with #{batch.size} failed to process due to '#{e.message}' - batch: #{batch.inspect}"
            @on_error.call(e, ident_str) if @on_error
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

  def tick(period)
    loop do
      sleep(period)

      @mutex.synchronize do
        @queue << [:process, :tick]
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
    Batcher.logger || NullLogger
  end
end

require 'batcher/railtie' if defined?(Rails)
