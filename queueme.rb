
class Queueme
  def initialize(redis, queue_name, options = {})
    raise ArgumentError, "First argument must be a non empty string" if !queue_name.is_a?(String) || queue_name.empty?

    @redis = redis
    @queue_name = queue_name
    @control_queue_name = "#{queue_name}--control"
    @last_message = nil
    @timeout = options[:timeout] ||= 0
  end

  def length
    @redis.llen @queue_name
  end

  def clear(clear_process_queue = false)
    @redis.del @queue_name
    @redis.del @control_queue_name if clear_process_queue
  end

  def empty?
    length <= 0
  end

  def push(obj)
    @redis.lpush(@queue_name, obj)
  end

  def pop(non_block = false)
    @last_message = if non_block
                      @redis.rpoplpush(@queue_name, @control_queue_name)
                    else
                      @redis.brpoplpush(@queue_name, @control_queue_name, @timeout)
                    end
    @last_message
  end

  def clear
    @redis.lrem(@control_queue_name, 0, @last_message)
  end

  def process(non_block = false, timeout = nil)
    @timeout = timeout unless timeout.nil?
    loop do
      message = pop(non_block)
      ret = yield message if block_given?
      clear if ret
      break if message.nil? || (non_block && empty?)
    end
  end

  def refill
    while (message = @redis.lpop(@control_queue_name))
      @redis.rpush(@queue_name, message)
    end
    true
  end

  alias size  length
  alias dec   pop
  alias shift pop
  alias enc   push
  alias <<    push
end

