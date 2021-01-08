require "bundler/inline"
require_relative "queueme.rb"
require_relative "queuer.rb"
require "securerandom"

gemfile do
  source "https://rubygems.org"
  gem "redis"
  gem "pry"
end

redis = Redis.new(host: "localhost", port: 6379)
q = Queuer.new(redis, ["q1r","q2r", "q3r"])

queue_threads= []
1..10.times do |number|
  thread_lambda = -> { Thread.new {q.enque(number.to_s)} }
  queue_threads.push(thread_lambda)
end
queue_threads.map {|thread_lambda| thread_lambda.call.join}

1..10.times do |number|
  p q.deque
end