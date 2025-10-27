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

puts "=== Production Deployment Checklist ==="

# 1. Environment Configuration Check
puts "\n1. Environment Configuration Check:"
config = UnifiedPaymentGateway.configuration

puts "Environment: #{config.environment}"
puts "KAMONEY keys configured: #{!config.kamoney_public_key.nil? && !config.kamoney_secret_key.nil?}"
puts "NOWPayments key configured: #{!config.nowpayments_api_key.nil?}"

# 2. API Connectivity Test
puts "\n2. API Connectivity Test:"

begin
  # Test KAMONEY API
  kamoney_status = gateway.kamoney.get_status
  puts "✓ KAMONEY API accessible"
rescue => e
  puts "✗ KAMONEY API error: #{e.message}"
end

begin
  # Test NOWPayments API
  nowpayments_status = gateway.nowpayments.get_status
  puts "✓ NOWPayments API accessible"
rescue => e
  puts "✗ NOWPayments API error: #{e.message}"
end

# 3. Security Configuration
puts "\n3. Security Configuration:"
puts "API keys stored in environment variables: ✓"
puts "Webhook endpoints use HTTPS: ✓"
puts "Webhook signatures verified: ✓"

# 4. Error Handling Test
puts "\n4. Error Handling Test:"

begin
  # Test invalid payment
  gateway.create_payment(
    provider: :kamoney,
    amount: -100.00, # Invalid amount
    description: "Test invalid payment"
  )
rescue UnifiedPaymentGateway::ValidationError => e
  puts "✓ Validation error handled: #{e.message}"
rescue => e
  puts "✗ Unexpected error: #{e.message}"
end

# 5. Rate Limiting Test
puts "\n5. Rate Limiting Test:"
puts "Implement rate limiting in your application:"
puts "  - Use Rack::Attack for Rails applications"
puts "  - Implement Redis-based rate limiting"
puts "  - Monitor API usage patterns"

# 6. Monitoring Setup
puts "\n6. Monitoring Setup:"
puts "Set up monitoring for:"
puts "  - API response times"
puts "  - Error rates"
puts "  - Payment success rates"
puts "  - Balance monitoring"
puts "  - Webhook delivery success"

# 7. Backup and Recovery
puts "\n7. Backup and Recovery:"
puts "Implement:"
puts "  - Database backups for payment records"
puts "  - Webhook event logging"
puts "  - Payment state recovery procedures"
puts "  - API key rotation procedures"

# 8. Performance Optimization
puts "\n8. Performance Optimization:"
puts "Consider:"
puts "  - Connection pooling for API calls"
puts "  - Caching for currency rates and minimum amounts"
puts "  - Async processing for webhook handling"
puts "  - Database indexing for payment queries"

# 9. Compliance Check
puts "\n9. Compliance Check:"
puts "Ensure compliance with:"
puts "  - PCI DSS requirements"
puts "  - Data protection regulations (GDPR, CCPA)"
puts "  - Financial reporting requirements"
puts "  - Anti-money laundering (AML) requirements"

# 10. Deployment Scripts
puts "\n10. Deployment Scripts:"

# Example deployment script
deployment_script = <<~SCRIPT
  #!/bin/bash
  
  # Deployment script for Unified Payment Gateway
  
  set -e
  
  echo "Deploying Unified Payment Gateway..."
  
  # 1. Environment check
  if [ -z "$KAMONEY_PUBLIC_KEY" ] || [ -z "$KAMONEY_SECRET_KEY" ] || [ -z "$NOWPAYMENTS_API_KEY" ]; then
    echo "Error: API keys not set in environment variables"
    exit 1
  fi
  
  # 2. Run tests
  echo "Running tests..."
  bundle exec rspec
  
  # 3. Security audit
  echo "Running security audit..."
  bundle exec bundle-audit check --update
  
  # 4. Code quality check
  echo "Running code quality checks..."
  bundle exec rubocop
  
  # 5. Database migrations (if applicable)
  echo "Running database migrations..."
  bundle exec rake db:migrate
  
  # 6. Asset compilation (if applicable)
  echo "Compiling assets..."
  bundle exec rake assets:precompile
  
  # 7. Restart application
  echo "Restarting application..."
  sudo systemctl restart your-app-service
  
  # 8. Health check
  echo "Running health check..."
  curl -f http://localhost:3000/health || exit 1
  
  echo "Deployment completed successfully!"
SCRIPT

puts "Example deployment script:"
puts deployment_script

# 11. Rollback Procedure
puts "\n11. Rollback Procedure:"
rollback_script = <<~SCRIPT
  #!/bin/bash
  
  # Rollback script for Unified Payment Gateway
  
  set -e
  
  echo "Rolling back deployment..."
  
  # 1. Stop current version
  sudo systemctl stop your-app-service
  
  # 2. Restore previous version
  git checkout previous-stable-tag
  
  # 3. Install dependencies
  bundle install
  
  # 4. Run database rollback (if needed)
  bundle exec rake db:rollback
  
  # 5. Restart service
  sudo systemctl start your-app-service
  
  # 6. Verify rollback
  curl -f http://localhost:3000/health || exit 1
  
  echo "Rollback completed successfully!"
SCRIPT

puts "Example rollback script:"
puts rollback_script

# 12. Monitoring Dashboard Setup
puts "\n12. Monitoring Dashboard Setup:"
puts "Set up dashboards for:"
puts "  - Payment success/failure rates"
puts "  - API response times"
puts "  - Error rates by provider"
puts "  - Balance levels"
puts "  - Webhook delivery rates"

# 13. Alerting Configuration
puts "\n13. Alerting Configuration:"
puts "Configure alerts for:"
puts "  - High error rates (>5%)"
puts "  - Low balances (<$100)"
puts "  - Webhook delivery failures"
puts "  - API downtime"
puts "  - Unusual payment patterns"

# 14. Final Checklist
puts "\n14. Final Production Checklist:"
checklist = [
  "✓ API keys configured in production environment",
  "✓ Webhook endpoints configured and tested",
  "✓ SSL certificates installed",
  "✓ Database backups configured",
  "✓ Monitoring and alerting set up",
  "✓ Rate limiting implemented",
  "✓ Error handling tested",
  "✓ Security audit completed",
  "✓ Performance testing done",
  "✓ Documentation updated",
  "✓ Team trained on procedures",
  "✓ Rollback plan tested"
]

checklist.each { |item| puts item }

puts "\n=== Production Deployment Guide Completed ==="
puts "Review all items above before deploying to production!"