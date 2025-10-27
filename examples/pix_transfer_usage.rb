# frozen_string_literal: true

require "unified_payment_gateway"

# Example configuration
UnifiedPaymentGateway.configure do |config|
  config.kamoney_public_key = ENV["KAMONEY_PUBLIC_KEY"]
  config.kamoney_secret_key = ENV["KAMONEY_SECRET_KEY"]
  config.environment = :development
  config.logger = Logger.new(STDOUT)
end

# Initialize gateway
gateway = UnifiedPaymentGateway::Gateway.new

puts "=== KAMONEY PIX Transfer Example ==="
puts "This example shows how to send PIX payments to other PIX keys"

# Send PIX payment to another PIX key
begin
  pix_transfer = gateway.send_kamoney_pix_payment(
    amount: 50.00,
    pix_key: "recipient@example.com",  # Can be CPF, CNPJ, email, phone, or random key
    description: "Payment for services",
    external_id: "transfer-123"
  )
  
  puts "PIX Transfer sent successfully!"
  puts "Transfer ID: #{pix_transfer[:transfer_id]}"
  puts "Status: #{pix_transfer[:status]}"
  puts "Amount: R$ #{pix_transfer[:amount]}"
  puts "PIX Key: #{pix_transfer[:pix_key]}"
  puts "Created at: #{pix_transfer[:created_at]}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error sending PIX transfer: #{e.message}"
end

puts "\n=== Alternative Method: kamoney_pix_transfer ==="

# Alternative method (also uses send_pix_payment internally)
begin
  pix_transfer_alt = gateway.kamoney_pix_transfer(
    amount: 25.00,
    pix_key: "another-recipient@example.com",
    description: "Alternative transfer method"
  )
  
  puts "Alternative PIX Transfer sent!"
  puts "Response: #{pix_transfer_alt}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error with alternative method: #{e.message}"
end

puts "\n=== PIX Transfer vs PIX Payment ==="
puts "- create_kamoney_pix_payment: Creates a PIX payment to receive money (generates QR code)"
puts "- send_kamoney_pix_payment: Sends PIX payment to another PIX key (transfers money)"
puts "- kamoney_pix_transfer: Alias for send_kamoney_pix_payment"

puts "\n=== Important Notes ==="
puts "1. Make sure your KAMONEY account has sufficient balance"
puts "2. PIX key can be: CPF, CNPJ, email, phone number, or random key"
puts "3. The external_id should be unique for each transfer"
puts "4. Transfers are usually processed instantly"
puts "5. Check your KAMONEY dashboard for transfer status"

puts "\n=== Check Balance Before Transfer ==="
begin
  balance = gateway.get_balance(:kamoney)
  puts "Available Balance: R$ #{balance['data']['available_balance']}"
  puts "Pending Balance: R$ #{balance['data']['pending_balance']}"
  
rescue UnifiedPaymentGateway::PaymentGatewayError => e
  puts "Error getting balance: #{e.message}"
end