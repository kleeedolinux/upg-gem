# frozen_string_literal: true

require "unified_payment_gateway"

# Example configuration
UnifiedPaymentGateway.configure do |config|
  config.kamoney_public_key = ENV["KAMONEY_PUBLIC_KEY"]
  config.kamoney_secret_key = ENV["KAMONEY_SECRET_KEY"]
  config.nowpayments_api_key = ENV["NOWPAYMENTS_API_KEY"]
  config.environment = :development
  config.logger = Logger.new(STDOUT)
end

# Initialize gateway
gateway = UnifiedPaymentGateway::Gateway.new

puts "=== KAMONEY PIX Payment Example ==="

# Create PIX payment
begin
  pix_payment = gateway.kamoney_pix_payment(
    amount: 100.00,
    description: "Test PIX payment",
    external_id: "order-123"
  )
  
  puts "PIX Payment created:"
  puts "Transaction ID: #{pix_payment['data']['transaction_id']}"
  puts "QR Code: #{pix_payment['data']['qr_code']}"
  puts "PIX Key: #{pix_payment['data']['pix_key']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error creating PIX payment: #{e.message}"
end

puts "\n=== NOWPayments Crypto Payment Example ==="

# Create crypto payment
begin
  crypto_payment = gateway.nowpayments_crypto_payment(
    price_amount: 50.00,
    price_currency: "usd",
    pay_currency: "btc",
    ipn_callback_url: "https://example.com/webhook"
  )
  
  puts "Crypto Payment created:"
  puts "Payment ID: #{crypto_payment['payment_id']}"
  puts "Status: #{crypto_payment['payment_status']}"
  puts "Pay Address: #{crypto_payment['pay_address']}"
  puts "Pay Amount: #{crypto_payment['pay_amount']} BTC"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error creating crypto payment: #{e.message}"
end

puts "\n=== Check Balances Example ==="

# Check KAMONEY balance
begin
  kamoney_balance = gateway.get_balance(:kamoney)
  puts "KAMONEY Balance:"
  puts "Available: R$ #{kamoney_balance['data']['available_balance']}"
  puts "Pending: R$ #{kamoney_balance['data']['pending_balance']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting KAMONEY balance: #{e.message}"
end

# Check NOWPayments balance
begin
  nowpayments_balance = gateway.get_balance(:nowpayments)
  puts "\nNOWPayments Balance:"
  puts "Available: $ #{nowpayments_balance['available_balance']}"
  puts "Pending: $ #{nowpayments_balance['pending_balance']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting NOWPayments balance: #{e.message}"
end

puts "\n=== Supported Currencies Example ==="

# Get supported cryptocurrencies
begin
  currencies = gateway.nowpayments.get_currencies
  puts "Supported cryptocurrencies: #{currencies['currencies'].join(', ')}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting currencies: #{e.message}"
end

puts "\n=== Unified Interface Example ==="

# Using the unified interface
begin
  # Create payment with KAMONEY
  payment1 = gateway.create_payment(
    provider: :kamoney,
    amount: 75.00,
    description: "Unified KAMONEY payment",
    external_id: "unified-123"
  )
  puts "Unified KAMONEY payment created"
  
  # Create payment with NOWPayments
  payment2 = gateway.create_payment(
    provider: :nowpayments,
    price_amount: 200.00,
    price_currency: "usd",
    pay_currency: "eth"
  )
  puts "Unified NOWPayments payment created"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error with unified interface: #{e.message}"
end

puts "\n=== Error Handling Example ==="

# Demonstrate error handling
begin
  # This will raise an error due to missing configuration
  gateway.create_payment(provider: :invalid)
  
rescue ArgumentError => e
  puts "Expected error caught: #{e.message}"
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Payment gateway error: #{e.message}"
end