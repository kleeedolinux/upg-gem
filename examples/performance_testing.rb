# frozen_string_literal: true

require "unified_payment_gateway"

# Configure the gateway
UnifiedPaymentGateway.configure do |config|
  config.kamoney_public_key = ENV["KAMONEY_PUBLIC_KEY"]
  config.kamoney_secret_key = ENV["KAMONEY_SECRET_KEY"]
  config.nowpayments_api_key = ENV["NOWPAYMENTS_API_KEY"]
  config.environment = :production
  config.logger = Logger.new(STDOUT, level: Logger::INFO)
end

gateway = UnifiedPaymentGateway::Gateway.new

puts "=== Performance Testing Suite ==="

# 1. Load Testing
puts "\n1. Load Testing:"

def load_test_payments(gateway, num_requests = 100, concurrent_threads = 10)
  require 'concurrent'
  
  puts "Running load test: #{num_requests} requests with #{concurrent_threads} threads"
  
  start_time = Time.now
  success_count = 0
  error_count = 0
  
  pool = Concurrent::FixedThreadPool.new(concurrent_threads)
  
  num_requests.times do |i|
    pool.post do
      begin
        # Simulate payment creation
        gateway.create_payment(
          provider: [:kamoney, :nowpayments].sample,
          amount: rand(10..1000),
          description: "Load test payment #{i}"
        )
        success_count += 1
      rescue => e
        error_count += 1
        puts "Error in request #{i}: #{e.message}"
      end
    end
  end
  
  pool.shutdown
  pool.wait_for_termination(60) # Wait up to 60 seconds
  
  end_time = Time.now
  duration = end_time - start_time
  
  puts "Load test completed in #{duration.round(2)} seconds"
  puts "Success: #{success_count} (#{(success_count.to_f / num_requests * 100).round(1)}%)"
  puts "Errors: #{error_count} (#{(error_count.to_f / num_requests * 100).round(1)}%)"
  puts "Requests per second: #{(num_requests / duration).round(2)}"
end

# Uncomment to run load test (be careful with API limits)
# load_test_payments(gateway, 50, 5)

# 2. Response Time Testing
puts "\n2. Response Time Testing:"

def measure_response_times(gateway, num_calls = 10)
  puts "Measuring response times for #{num_calls} calls..."
  
  response_times = {
    kamoney_status: [],
    kamoney_balance: [],
    nowpayments_status: [],
    nowpayments_currencies: []
  }
  
  num_calls.times do |i|
    puts "Call #{i + 1}/#{num_calls}"
    
    # KAMONEY status
    start_time = Time.now
    begin
      gateway.kamoney.get_status
      response_times[:kamoney_status] << (Time.now - start_time)
    rescue => e
      puts "KAMONEY status error: #{e.message}"
    end
    
    # KAMONEY balance
    start_time = Time.now
    begin
      gateway.get_balance(:kamoney)
      response_times[:kamoney_balance] << (Time.now - start_time)
    rescue => e
      puts "KAMONEY balance error: #{e.message}"
    end
    
    # NOWPayments status
    start_time = Time.now
    begin
      gateway.nowpayments.get_status
      response_times[:nowpayments_status] << (Time.now - start_time)
    rescue => e
      puts "NOWPayments status error: #{e.message}"
    end
    
    # NOWPayments currencies
    start_time = Time.now
    begin
      gateway.nowpayments.get_currencies
      response_times[:nowpayments_currencies] << (Time.now - start_time)
    rescue => e
      puts "NOWPayments currencies error: #{e.message}"
    end
    
    sleep(0.5) # Small delay between calls
  end
  
  # Calculate statistics
  response_times.each do |endpoint, times|
    next if times.empty?
    
    avg_time = times.sum / times.size
    min_time = times.min
    max_time = times.max
    
    puts "\n#{endpoint}:"
    puts "  Average: #{(avg_time * 1000).round(2)}ms"
    puts "  Minimum: #{(min_time * 1000).round(2)}ms"
    puts "  Maximum: #{(max_time * 1000).round(2)}ms"
  end
end

measure_response_times(gateway, 5)

# 3. Memory Usage Testing
puts "\n3. Memory Usage Testing:"

def test_memory_usage(gateway)
  puts "Testing memory usage..."
  
  # Get initial memory usage
  initial_memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  puts "Initial memory usage: #{initial_memory.round(2)} MB"
  
  # Create many payment objects
  payments = []
  100.times do |i|
    begin
      payment = gateway.create_payment(
        provider: [:kamoney, :nowpayments].sample,
        amount: rand(10..100),
        description: "Memory test payment #{i}"
      )
      payments << payment
    rescue => e
      puts "Error creating payment #{i}: #{e.message}"
    end
  end
  
  # Check memory after creating payments
  after_create_memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  puts "Memory after creating payments: #{after_create_memory.round(2)} MB"
  puts "Memory increase: #{(after_create_memory - initial_memory).round(2)} MB"
  
  # Clear references
  payments.clear
  GC.start
  
  # Check memory after garbage collection
  after_gc_memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024.0
  puts "Memory after garbage collection: #{after_gc_memory.round(2)} MB"
  puts "Memory recovered: #{(after_create_memory - after_gc_memory).round(2)} MB"
end

test_memory_usage(gateway)

# 4. Connection Pool Testing
puts "\n4. Connection Pool Testing:"

def test_connection_pooling(gateway)
  puts "Testing connection pooling..."
  
  # Test with different pool sizes
  [1, 5, 10].each do |pool_size|
    puts "\nTesting with pool size: #{pool_size}"
    
    start_time = Time.now
    
    threads = []
    pool_size.times do |i|
      threads << Thread.new do
        begin
          gateway.kamoney.get_status
          puts "Thread #{i}: Connection successful"
        rescue => e
          puts "Thread #{i}: Connection failed - #{e.message}"
        end
      end
    end
    
    threads.each(&:join)
    
    end_time = Time.now
    puts "Pool size #{pool_size} completed in #{(end_time - start_time).round(2)} seconds"
  end
end

test_connection_pooling(gateway)

# 5. Caching Strategy Testing
puts "\n5. Caching Strategy Testing:"

def test_caching_strategy(gateway)
  puts "Testing caching strategies..."
  
  # Test currency caching
  puts "Testing currency caching..."
  
  # First call (should hit API)
  start_time = Time.now
  currencies1 = gateway.nowpayments.get_currencies
  first_call_time = Time.now - start_time
  
  # Second call (should be cached)
  start_time = Time.now
  currencies2 = gateway.nowpayments.get_currencies
  second_call_time = Time.now - start_time
  
  puts "First call time: #{(first_call_time * 1000).round(2)}ms"
  puts "Second call time: #{(second_call_time * 1000).round(2)}ms"
  puts "Caching improvement: #{((first_call_time - second_call_time) / first_call_time * 100).round(1)}%"
  
  # Test minimum amount caching
  puts "\nTesting minimum amount caching..."
  
  start_time = Time.now
  min_amount1 = gateway.nowpayments.get_minimum_amount("usd", "btc")
  first_min_time = Time.now - start_time
  
  start_time = Time.now
  min_amount2 = gateway.nowpayments.get_minimum_amount("usd", "btc")
  second_min_time = Time.now - start_time
  
  puts "First min amount call: #{(first_min_time * 1000).round(2)}ms"
  puts "Second min amount call: #{(second_min_time * 1000).round(2)}ms"
end

test_caching_strategy(gateway)

# 6. Error Rate Testing
puts "\n6. Error Rate Testing:"

def test_error_rates(gateway, num_tests = 20)
  puts "Testing error rates with #{num_tests} invalid requests..."
  
  error_types = {
    validation: 0,
    network: 0,
    rate_limit: 0,
    authentication: 0,
    other: 0
  }
  
  num_tests.times do |i|
    begin
      # Test with invalid parameters
      gateway.create_payment(
        provider: :kamoney,
        amount: -100, # Invalid amount
        description: "Error test #{i}"
      )
    rescue UnifiedPaymentGateway::ValidationError => e
      error_types[:validation] += 1
    rescue UnifiedPaymentGateway::NetworkError => e
      error_types[:network] += 1
    rescue UnifiedPaymentGateway::RateLimitError => e
      error_types[:rate_limit] += 1
    rescue UnifiedPaymentGateway::AuthenticationError => e
      error_types[:authentication] += 1
    rescue => e
      error_types[:other] += 1
    end
  end
  
  puts "Error distribution:"
  error_types.each do |type, count|
    percentage = (count.to_f / num_tests * 100).round(1)
    puts "  #{type}: #{count} (#{percentage}%)"
  end
end

test_error_rates(gateway)

# 7. Performance Recommendations
puts "\n7. Performance Recommendations:"
recommendations = [
  "Implement connection pooling for API calls",
  "Cache frequently accessed data (currencies, minimum amounts)",
  "Use Redis for distributed caching in production",
  "Implement circuit breaker pattern for API failures",
  "Use background jobs for webhook processing",
  "Monitor API rate limits and implement backoff strategies",
  "Optimize database queries for payment records",
  "Use CDN for static assets in web applications",
  "Implement request batching where possible",
  "Monitor memory usage and implement memory limits"
]

recommendations.each_with_index do |rec, i|
  puts "#{i + 1}. #{rec}"
end

puts "\n=== Performance Testing Suite Completed ==="
puts "Review results above and implement optimizations as needed."