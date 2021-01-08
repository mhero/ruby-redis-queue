class Queuer
  QUEUE_NUMBBER = 3

  def initialize(redis, queue_names)
    raise ArgumentError, "Too many queues" if queue_names.length > QUEUE_NUMBBER

    @queues = queue_names.map do |queue|
      {
        name: queue,
        queue: Queueme.new(redis, queue),
        status: true,
      }
    end

    @leading_queue = Queue.new
  end

  def find(queue_name)
    @queues.detect { |el| el[:name] == queue_name }
  end

  def disabler(queue_name)
    queue_found = find(queue_name)
    queue_found[:status] = false
  end

  def enabler(queue_name)
    queue_found = find(queue_name)
    queue_found[:status] = true
  end

  def active
    queue_found = @queues.select { |el| el[:status] == true }
  end

  def enque(objekt)
    queue = active.sample
    queue[:queue].push(objekt)
    @leading_queue << queue[:name]
  end

  def deque
    queue_found = find(@leading_queue.pop)
    value = queue_found[:queue].pop
    queue_found[:queue].clear
    "#{queue_found[:name]}-#{value}"
  end
end