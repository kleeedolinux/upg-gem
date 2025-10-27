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

puts "=== KAMONEY Crypto Functionality Demo ==="

# Example 1: Get withdrawal history
puts "\n1. Getting withdrawal history:"

begin
  withdrawals = gateway.get_kamoney_withdrawals_list
  
  if withdrawals['data'] && !withdrawals['data'].empty?
    puts "Recent withdrawals:"
    withdrawals['data'].first(3).each do |withdrawal|
      puts "  - #{withdrawal['id']}: #{withdrawal['amount']} #{withdrawal['currency']} (#{withdrawal['status']})"
    end
  else
    puts "No withdrawals found"
  end
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting withdrawals: #{e.message}"
end

# Example 2: Create crypto withdrawal from PIX balance
puts "\n2. Creating crypto withdrawal from PIX balance:"

begin
  crypto_withdrawal = gateway.create_kamoney_crypto_withdrawal(
    amount: 150.00,
    currency: "btc",
    wallet_address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
    description: "Withdraw BTC from PIX balance"
  )
  
  puts "Crypto withdrawal created: #{crypto_withdrawal['data']['withdrawal_id']}"
  puts "Status: #{crypto_withdrawal['data']['status']}"
  puts "Network fee: #{crypto_withdrawal['data']['network_fee']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Crypto withdrawal error: #{e.message}"
end

# Example 3: Convert PIX payment to crypto
puts "\n3. Converting PIX payment to cryptocurrency:"

begin
  # First create a PIX payment
  pix_payment = gateway.kamoney_pix_payment(
    amount: 200.00,
    description: "PIX for crypto conversion",
    external_id: "pix-crypto-001"
  )
  
  puts "PIX payment created: #{pix_payment['data']['transaction_id']}"
  
  # Convert PIX to crypto
  conversion = gateway.create_kamoney_pix_to_crypto_conversion(
    pix_transaction_id: pix_payment['data']['transaction_id'],
    target_currency: "eth",
    wallet_address: "0x742d35Cc6634C0532925a3b844Bc9e7595f5256e"
  )
  
  puts "PIX to crypto conversion created: #{conversion['data']['conversion_id']}"
  puts "Estimated crypto amount: #{conversion['data']['estimated_amount']} ETH"
  puts "Exchange rate: #{conversion['data']['exchange_rate']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "PIX to crypto conversion error: #{e.message}"
end

# Example 4: Get crypto deposit address
puts "\n4. Getting crypto deposit address:"

begin
  deposit_address = gateway.get_kamoney_crypto_deposit_address(
    currency: "usdt",
    network: "trc20"
  )
  
  puts "USDT deposit address: #{deposit_address['data']['address']}"
  puts "Network: #{deposit_address['data']['network']}"
  puts "Tag/Memo: #{deposit_address['data']['tag']}" if deposit_address['data']['tag']
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting deposit address: #{e.message}"
end

# Example 5: Get exchange rates
puts "\n5. Getting exchange rates:"

begin
  exchange_rates = gateway.get_kamoney_exchange_rates(
    from_currency: "brl",
    to_currency: "btc"
  )
  
  puts "BRL to BTC exchange rate: #{exchange_rates['data']['rate']}"
  puts "Last updated: #{exchange_rates['data']['timestamp']}"
  
  # Get rates for multiple currencies
  currencies = ["btc", "eth", "usdt", "usdc"]
  currencies.each do |currency|
    rates = gateway.get_kamoney_exchange_rates(
      from_currency: "brl",
      to_currency: currency
    )
    puts "  BRL to #{currency.upcase}: #{rates['data']['rate']}"
  end
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting exchange rates: #{e.message}"
end

# Example 6: Create exchange swap
puts "\n6. Creating exchange swap:"

begin
  swap = gateway.create_kamoney_exchange_swap(
    from_currency: "btc",
    to_currency: "eth",
    from_amount: 0.01,
    wallet_address: "0x742d35Cc6634C0532925a3b844Bc9e7595f5256e"
  )
  
  puts "Exchange swap created: #{swap['data']['swap_id']}"
  puts "From: #{swap['data']['from_amount']} BTC"
  puts "To: #{swap['data']['to_amount']} ETH"
  puts "Exchange rate: #{swap['data']['exchange_rate']}"
  puts "Network fee: #{swap['data']['network_fee']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Exchange swap error: #{e.message}"
end

puts "\n=== NOWPayments Mass Payout Demo ==="

# Example 7: Create mass payout
puts "\n7. Creating mass payout:"

begin
  # Prepare multiple recipients
  recipients = [
    {
      address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh",
      amount: 0.001,
      currency: "btc"
    },
    {
      address: "0x742d35Cc6634C0532925a3b844Bc9e7595f5256e",
      amount: 0.01,
      currency: "eth"
    },
    {
      address: "TRON_ADDRESS_HERE",
      amount: 10,
      currency: "usdt",
      network: "trc20"
    }
  ]
  
  mass_payout = gateway.create_nowpayments_mass_payout(
    recipients: recipients,
    total_amount: 100.00,
    currency: "usd",
    description: "Monthly affiliate payments"
  )
  
  puts "Mass payout created: #{mass_payout['data']['batch_id']}"
  puts "Total recipients: #{mass_payout['data']['total_recipients']}"
  puts "Estimated total: #{mass_payout['data']['estimated_total']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Mass payout error: #{e.message}"
end

# Example 8: Get mass payout status
puts "\n8. Getting mass payout status:"

begin
  # Get list of mass payouts first
  payouts_list = gateway.get_nowpayments_mass_payouts_list(
    limit: 5
  )
  
  if payouts_list['data'] && !payouts_list['data'].empty?
    latest_payout = payouts_list['data'].first
    
    status = gateway.get_nowpayments_mass_payout_status(
      batch_id: latest_payout['batch_id']
    )
    
    puts "Mass payout status: #{status['data']['status']}"
    puts "Processed: #{status['data']['processed_recipients']}/#{status['data']['total_recipients']}"
    puts "Total amount: #{status['data']['total_amount']}"
  else
    puts "No mass payouts found"
  end
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting mass payout status: #{e.message}"
end

# Example 9: Get payout limits
puts "\n9. Getting payout limits:"

begin
  limits = gateway.get_nowpayments_payout_limits
  
  puts "Payout limits:"
  puts "  Minimum payout: #{limits['data']['minimum_payout']}"
  puts "  Maximum payout: #{limits['data']['maximum_payout']}"
  puts "  Daily limit: #{limits['data']['daily_limit']}"
  puts "  Monthly limit: #{limits['data']['monthly_limit']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting payout limits: #{e.message}"
end

# Example 10: Validate payout address
puts "\n10. Validating payout addresses:"

test_addresses = [
  { address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", currency: "btc" },
  { address: "0x742d35Cc6634C0532925a3b844Bc9e7595f5256e", currency: "eth" },
  { address: "invalid_address", currency: "btc" }
]

test_addresses.each do |test|
  begin
    validation = gateway.validate_nowpayments_payout_address(
      address: test[:address],
      currency: test[:currency]
    )
    
    puts "#{test[:address]} (#{test[:currency].upcase}): #{validation['data']['valid'] ? 'Valid' : 'Invalid'}"
    puts "  Network: #{validation['data']['network']}" if validation['data']['network']
    
  rescue UnifiedPaymentGateway::PaymentGatewayError => e
    puts "#{test[:address]} validation error: #{e.message}"
  end
end

# Example 11: Get available payout currencies
puts "\n11. Available payout currencies:"

begin
  currencies = gateway.get_nowpayments_available_payout_currencies
  
  puts "Available payout currencies:"
  currencies['data'].first(10).each do |currency|
    puts "  - #{currency['code'].upcase}: #{currency['name']}"
    puts "    Min payout: #{currency['minimum_payout']}"
    puts "    Networks: #{currency['networks'].join(', ')}" if currency['networks']
  end
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting payout currencies: #{e.message}"
end

puts "\n=== Complete Integration Example ==="

# Example 12: Complete workflow - PIX to mass crypto payout
puts "\n12. Complete workflow: PIX payment → crypto conversion → mass payout"

begin
  # Step 1: Create PIX payment
  puts "Step 1: Creating PIX payment..."
  pix_payment = gateway.kamoney_pix_payment(
    amount: 500.00,
    description: "Complete workflow demo",
    external_id: "complete-demo-001"
  )
  puts "PIX payment created: #{pix_payment['data']['transaction_id']}"
  
  # Step 2: Convert PIX to crypto
  puts "Step 2: Converting PIX to crypto..."
  conversion = gateway.create_kamoney_pix_to_crypto_conversion(
    pix_transaction_id: pix_payment['data']['transaction_id'],
    target_currency: "usdt",
    wallet_address: "TEMP_WALLET_ADDRESS"
  )
  puts "Conversion created: #{conversion['data']['conversion_id']}"
  
  # Step 3: Prepare mass payout recipients
  puts "Step 3: Preparing mass payout..."
  recipients = [
    { address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh", amount: 50, currency: "usdt", network: "trc20" },
    { address: "0x742d35Cc6634C0532925a3b844Bc9e7595f5256e", amount: 50, currency: "usdt", network: "erc20" }
  ]
  
  mass_payout = gateway.create_nowpayments_mass_payout(
    recipients: recipients,
    total_amount: 100.00,
    currency: "usd",
    description: "Automated affiliate payout"
  )
  puts "Mass payout created: #{mass_payout['data']['batch_id']}"
  
  puts "\n🎉 Complete workflow successful!"
  puts "   PIX → Crypto → Mass Payout completed in one flow"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Workflow error: #{e.message}"
end

puts "\n=== Demo completed! ==="
puts "All new crypto functionality has been demonstrated."
puts "Check the logs above for detailed responses and error messages."