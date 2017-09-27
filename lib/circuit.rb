class Circuit
  VERSION = "0.1.0"

  def initialize(payload:, max_failures: 100, retry_in: 60)
    @payload      = payload
    @max_failures = max_failures
    @retry_in     = retry_in

    @mutex = Mutex.new

    close
  end

  def pass(message, *args)
    fail @e if open? && !time_to_retry?
    result = payload.public_send(message, *args)
    close if open?
    result
  rescue => e
    @e = e
    @mutex.synchronize{ @failures[e.class] += 1 }
    break! if @failures[e.class] > max_failures
    raise e
  end

  def open?
    !closed?
  end

  def closed?
    @closed
  end

  private

  attr_reader :payload
  attr_reader :max_failures
  attr_reader :retry_in

  def break!
    @closed = false
    @broken_at = Time.now
  end

  def close
    @closed = true
    @failures = Hash.new(0)
  end

  def time_to_retry?
    @broken_at + retry_in < Time.now
  end
end
