# frozen_string_literal: true

require "unified_payment_gateway"

# Configure the gateway for sandbox environment
UnifiedPaymentGateway.configure do |config|
  config.kamoney_public_key = ENV["KAMONEY_PUBLIC_KEY"]
  config.kamoney_secret_key = ENV["KAMONEY_SECRET_KEY"]
  config.nowpayments_api_key = ENV["NOWPAYMENTS_API_KEY"]
  config.environment = :development
  config.logger = Logger.new(STDOUT, level: Logger::DEBUG)
end

gateway = UnifiedPaymentGateway::Gateway.new

puts "=== Webhook Integration Examples ==="

# Example 1: KAMONEY Webhook Handler
class KamoneyWebhookHandler
  def initialize(gateway)
    @gateway = gateway
  end

  def handle_webhook(request_body, signature_header)
    # Verify webhook signature
    if verify_signature(request_body, signature_header)
      payload = JSON.parse(request_body)
      
      case payload['event_type']
      when 'payment.completed'
        handle_payment_completed(payload)
      when 'payment.failed'
        handle_payment_failed(payload)
      when 'transfer.completed'
        handle_transfer_completed(payload)
      else
        puts "Unknown event type: #{payload['event_type']}"
      end
      
      { status: 'success' }
    else
      { status: 'error', message: 'Invalid signature' }
    end
  rescue JSON::ParserError => e
    { status: 'error', message: 'Invalid JSON' }
  rescue => e
    { status: 'error', message: e.message }
  end

  private

  def verify_signature(payload, signature)
    # Use KAMONEY secret key to verify HMAC signature
    expected_signature = @gateway.kamoney.generate_hmac_signature(payload)
    Rack::Utils.secure_compare(expected_signature, signature)
  end

  def handle_payment_completed(payload)
    transaction_id = payload['data']['transaction_id']
    amount = payload['data']['amount']
    
    puts "Payment completed: #{transaction_id} - R$ #{amount}"
    
    # Update your database, send confirmation email, etc.
    update_order_status(transaction_id, 'paid')
  end

  def handle_payment_failed(payload)
    transaction_id = payload['data']['transaction_id']
    error_message = payload['data']['error_message']
    
    puts "Payment failed: #{transaction_id} - #{error_message}"
    
    # Update order status, notify customer, etc.
    update_order_status(transaction_id, 'failed')
  end

  def handle_transfer_completed(payload)
    transaction_id = payload['data']['transaction_id']
    amount = payload['data']['amount']
    
    puts "Transfer completed: #{transaction_id} - R$ #{amount}"
    
    # Update payout records, notify recipient, etc.
    update_payout_status(transaction_id, 'completed')
  end

  def update_order_status(transaction_id, status)
    # Implement your database update logic here
    puts "Updating order #{transaction_id} status to: #{status}"
  end

  def update_payout_status(transaction_id, status)
    # Implement your database update logic here
    puts "Updating payout #{transaction_id} status to: #{status}"
  end
end

# Example 2: NOWPayments Webhook Handler
class NowPaymentsWebhookHandler
  def initialize(gateway)
    @gateway = gateway
  end

  def handle_webhook(request_body, authorization_header)
    # Verify webhook authorization
    if verify_authorization(authorization_header)
      payload = JSON.parse(request_body)
      
      case payload['payment_status']
      when 'finished'
        handle_payment_finished(payload)
      when 'failed'
        handle_payment_failed(payload)
      when 'confirmed'
        handle_payment_confirmed(payload)
      when 'sent'
        handle_payment_sent(payload)
      else
        puts "Unknown payment status: #{payload['payment_status']}"
      end
      
      { status: 'success' }
    else
      { status: 'error', message: 'Invalid authorization' }
    end
  rescue JSON::ParserError => e
    { status: 'error', message: 'Invalid JSON' }
  rescue => e
    { status: 'error', message: e.message }
  end

  private

  def verify_authorization(authorization)
    # Check if the authorization header matches your API key
    expected_auth = "Bearer #{@gateway.nowpayments.instance_variable_get(:@api_key)}"
    Rack::Utils.secure_compare(authorization, expected_auth)
  end

  def handle_payment_finished(payload)
    payment_id = payload['payment_id']
    amount = payload['pay_amount']
    currency = payload['pay_currency']
    
    puts "Crypto payment finished: #{payment_id} - #{amount} #{currency}"
    
    # Update order status, deliver digital goods, etc.
    update_order_status(payment_id, 'completed')
  end

  def handle_payment_confirmed(payload)
    payment_id = payload['payment_id']
    confirmations = payload['actually_paid']
    
    puts "Payment confirmed: #{payment_id} - #{confirmations} confirmations"
    
    # Update confirmation count in your system
    update_payment_confirmations(payment_id, confirmations)
  end

  def handle_payment_failed(payload)
    payment_id = payload['payment_id']
    error_message = payload['payment_error']
    
    puts "Crypto payment failed: #{payment_id} - #{error_message}"
    
    # Update order status, notify customer, etc.
    update_order_status(payment_id, 'failed')
  end

  def handle_payment_sent(payload)
    payment_id = payload['payment_id']
    
    puts "Payment sent: #{payment_id}"
    
    # Handle payout completion
    update_payout_status(payment_id, 'sent')
  end

  def update_order_status(payment_id, status)
    # Implement your database update logic here
    puts "Updating crypto order #{payment_id} status to: #{status}"
  end

  def update_payment_confirmations(payment_id, confirmations)
    # Implement your database update logic here
    puts "Updating payment #{payment_id} confirmations to: #{confirmations}"
  end

  def update_payout_status(payment_id, status)
    # Implement your database update logic here
    puts "Updating crypto payout #{payment_id} status to: #{status}"
  end
end

# Example 3: Rails Controller Integration
class PaymentWebhooksController
  def kamoney_webhook
    handler = KamoneyWebhookHandler.new(gateway)
    
    # In Rails, you would use: request.body.read
    # For this example, we'll simulate the request
    webhook_body = '{"event_type":"payment.completed","data":{"transaction_id":"txn_123","amount":100.00}}'
    signature = gateway.kamoney.generate_hmac_signature(webhook_body)
    
    result = handler.handle_webhook(webhook_body, signature)
    
    if result[:status] == 'success'
      puts "KAMONEY webhook processed successfully"
    else
      puts "KAMONEY webhook failed: #{result[:message]}"
    end
  end

  def nowpayments_webhook
    handler = NowPaymentsWebhookHandler.new(gateway)
    
    # Simulate NOWPayments webhook
    webhook_body = '{"payment_id":"pay_456","payment_status":"finished","pay_amount":0.05,"pay_currency":"btc"}'
    authorization = "Bearer #{ENV['NOWPAYMENTS_API_KEY']}"
    
    result = handler.handle_webhook(webhook_body, authorization)
    
    if result[:status] == 'success'
      puts "NOWPayments webhook processed successfully"
    else
      puts "NOWPayments webhook failed: #{result[:message]}"
    end
  end
end

# Example 4: Sinatra/Rails Integration
class WebhookServer
  def initialize(gateway)
    @gateway = gateway
    @kamoney_handler = KamoneyWebhookHandler.new(gateway)
    @nowpayments_handler = NowPaymentsWebhookHandler.new(gateway)
  end

  def call(env)
    request = Rack::Request.new(env)
    
    case request.path_info
    when '/webhooks/kamoney'
      handle_kamoney_webhook(request)
    when '/webhooks/nowpayments'
      handle_nowpayments_webhook(request)
    else
      [404, { 'Content-Type' => 'application/json' }, ['{"error":"Not found"}']]
    end
  end

  private

  def handle_kamoney_webhook(request)
    # Read request body
    body = request.body.read
    signature = request.env['HTTP_X_KAMONEY_SIGNATURE']
    
    result = @kamoney_handler.handle_webhook(body, signature)
    
    status = result[:status] == 'success' ? 200 : 400
    [status, { 'Content-Type' => 'application/json' }, [result.to_json]]
  end

  def handle_nowpayments_webhook(request)
    # Read request body
    body = request.body.read
    authorization = request.env['HTTP_AUTHORIZATION']
    
    result = @nowpayments_handler.handle_webhook(body, authorization)
    
    status = result[:status] == 'success' ? 200 : 400
    [status, { 'Content-Type' => 'application/json' }, [result.to_json]]
  end
end

# Example usage
puts "Testing webhook handlers..."

controller = PaymentWebhooksController.new
controller.kamoney_webhook
controller.nowpayments_webhook

puts "\n=== Webhook Security Best Practices ==="
puts "1. Always verify webhook signatures"
puts "2. Use HTTPS for webhook endpoints"
puts "3. Implement rate limiting"
puts "4. Log all webhook events"
puts "5. Implement idempotency (prevent duplicate processing)"
puts "6. Use secure comparison for signatures (Rack::Utils.secure_compare)"
puts "7. Validate webhook payload structure"
puts "8. Implement proper error handling and retries"

puts "\n=== Webhook Integration Examples Completed ==="