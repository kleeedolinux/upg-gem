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

puts "=== Advanced KAMONEY Examples ==="

# Example 1: Create order and process payment
puts "\n1. Creating order and processing PIX payment:"

begin
  # Create order
  order = gateway.kamoney.create_order(
    amount: 250.00,
    description: "Advanced order example",
    external_id: "adv-order-001"
  )
  
  puts "Order created: #{order['data']['order_id']}"
  
  # Create PIX payment for the order
  pix_payment = gateway.kamoney_pix_payment(
    amount: 250.00,
    description: "Payment for order #{order['data']['order_id']}",
    external_id: "pix-for-order-001"
  )
  
  puts "PIX payment created: #{pix_payment['data']['transaction_id']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error: #{e.message}"
end

# Example 2: Send PIX transfer with verification
puts "\n2. Sending PIX transfer:"

begin
  transfer = gateway.kamoney_pix_transfer(
    amount: 75.50,
    pix_key: "recipient@example.com",
    description: "Supplier payment"
  )
  
  puts "Transfer initiated: #{transfer['data']['transaction_id']}"
  puts "Status: #{transfer['data']['status']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Transfer error: #{e.message}"
end

# Example 3: List and monitor transactions
puts "\n3. Listing recent transactions:"

begin
  transactions = gateway.kamoney.list_transactions
  
  if transactions['data'] && !transactions['data'].empty?
    puts "Recent transactions:"
    transactions['data'].first(5).each do |txn|
      puts "  - #{txn['transaction_id']}: #{txn['amount']} (#{txn['status']})"
    end
  else
    puts "No transactions found"
  end
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error listing transactions: #{e.message}"
end

puts "\n=== Advanced NOWPayments Examples ==="

# Example 4: Multi-currency payment processing
puts "\n4. Multi-currency payment processing:"

currencies = ["btc", "eth", "usdt", "usdc"]
currencies.each do |currency|
  begin
    # Get minimum amount for the currency
    min_amount = gateway.nowpayments.get_minimum_amount("usd", currency)
    puts "Minimum #{currency.upcase} amount: #{min_amount['minimum_amount']}"
    
    # Get estimated price
    estimate = gateway.nowpayments.get_estimated_price(100, "usd", currency)
    puts "Estimated #{currency.upcase} for $100: #{estimate['estimated_amount']}"
    
  rescue UnifiedPaymentGateway::PaymentGatewayError => e
    puts "Error with #{currency}: #{e.message}"
  end
end

# Example 5: Create invoice for customer
puts "\n5. Creating invoice for customer:"

begin
  invoice = gateway.nowpayments.create_invoice(
    price_amount: 500.00,
    price_currency: "usd",
    order_id: "invoice-123",
    order_description: "Professional services"
  )
  
  puts "Invoice created: #{invoice['id']}"
  puts "Invoice URL: #{invoice['invoice_url']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Invoice error: #{e.message}"
end

# Example 6: Crypto payout with verification
puts "\n6. Processing crypto payout:"

begin
  # Create payout
  payout = gateway.nowpayments_crypto_payout(
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
    amount: 0.001,
    currency: "btc"
  )
  
  puts "Payout created: #{payout['id']}"
  puts "Status: #{payout['status']}"
  
  # Note: In production, you would verify the payout with a verification code
  # verification = gateway.nowpayments.verify_payout(payout['id'], verification_code)
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Payout error: #{e.message}"
end

puts "\n=== Error Handling and Retry Examples ==="

# Example 7: Robust error handling with retry logic
puts "\n7. Robust payment processing with error handling:"

def process_payment_with_retry(gateway, params, max_retries = 3)
  retries = 0
  
  begin
    puts "Attempting payment (try #{retries + 1})..."
    payment = gateway.create_payment(params)
    puts "Payment successful: #{payment['payment_id'] || payment['data']['transaction_id']}"
    return payment
    
  rescue UnifiedPaymentGateway::NetworkError => e
    retries += 1
    if retries < max_retries
      puts "Network error, retrying in #{retries} seconds..."
      sleep(retries)
      retry
    else
      puts "Max retries reached, failing payment"
      raise e
    end
    
  rescue UnifiedPaymentGateway::RateLimitError => e
    puts "Rate limit hit, waiting 60 seconds..."
    sleep(60)
    retry
    
  rescue UnifiedPaymentGateway::ValidationError => e
    puts "Validation error: #{e.message}"
    puts "Please check your payment parameters"
    return nil
    
  rescue UnifiedPaymentGateway::PaymentGatewayError => e
    puts "Payment gateway error: #{e.message}"
    return nil
  end
end

# Test with KAMONEY
kamoney_payment = process_payment_with_retry(gateway, {
  provider: :kamoney,
  amount: 100.00,
  description: "Retry test payment",
  external_id: "retry-test-001"
})

# Test with NOWPayments
nowpayments_payment = process_payment_with_retry(gateway, {
  provider: :nowpayments,
  price_amount: 150.00,
  price_currency: "usd",
  pay_currency: "eth"
})

puts "\n=== Monitoring and Status Checking ==="

# Example 8: Monitor payment status
puts "\n8. Monitoring payment status:"

def monitor_payment_status(gateway, provider, payment_id, max_checks = 5)
  checks = 0
  
  while checks < max_checks
    begin
      status = gateway.get_payment_status(provider, payment_id)
      
      if provider == :kamoney
        current_status = status['data']['status']
      else
        current_status = status['payment_status']
      end
      
      puts "Check #{checks + 1}: Status is '#{current_status}'"
      
      # Stop monitoring if payment is complete
      if ["paid", "finished", "completed"].include?(current_status.downcase)
        puts "Payment completed!"
        return true
      end
      
      checks += 1
      sleep(10) # Wait 10 seconds between checks
      
    rescue UnifiedPaymentGateway::PaymentGatewayError => e
      puts "Error checking status: #{e.message}"
      return false
    end
  end
  
  puts "Payment monitoring timeout"
  false
end

# Monitor the payments we created
if kamoney_payment
  payment_id = kamoney_payment['data']['transaction_id']
  monitor_payment_status(gateway, :kamoney, payment_id, 3)
end

if nowpayments_payment
  payment_id = nowpayments_payment['payment_id']
  monitor_payment_status(gateway, :nowpayments, payment_id, 3)
end

puts "\n=== Final Balance Check ==="

# Check final balances
begin
  kamoney_balance = gateway.get_balance(:kamoney)
  nowpayments_balance = gateway.get_balance(:nowpayments)
  
  puts "Final KAMONEY balance:"
  puts "  Available: R$ #{kamoney_balance['data']['available_balance']}"
  puts "  Pending: R$ #{kamoney_balance['data']['pending_balance']}"
  
  puts "Final NOWPayments balance:"
  puts "  Available: $ #{nowpayments_balance['available_balance']}"
  puts "  Pending: $ #{nowpayments_balance['pending_balance']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error checking final balances: #{e.message}"
end

puts "\n=== Example completed! ==="