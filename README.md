# UnifiedPaymentGateway

A Ruby gem that provides a unified interface for integrating with multiple payment gateways, including KAMONEY (PIX payments) and NOWPayments (cryptocurrency payments).

## Features

- **Unified Interface**: Single API for multiple payment providers
- **KAMONEY Integration**: Full support for PIX payments (receiving and sending)
- **NOWPayments Integration**: Complete cryptocurrency payment processing
- **Comprehensive Error Handling**: Custom error classes for different scenarios
- **Robust Logging**: Built-in logging with configurable levels
- **Retry Logic**: Automatic retry for transient failures
- **Test Coverage**: Comprehensive RSpec test suite
- **Environment Configuration**: Support for development and production environments

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'unified_payment_gateway'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install unified_payment_gateway
```

## Configuration

Configure the gem with your API credentials:

```ruby
require 'unified_payment_gateway'

UnifiedPaymentGateway.configure do |config|
  # KAMONEY credentials
  config.kamoney_public_key = 'your_kamoney_public_key'
  config.kamoney_secret_key = 'your_kamoney_secret_key'
  
  # NOWPayments credentials
  config.nowpayments_api_key = 'your_nowpayments_api_key'
  
  # Optional settings
  config.environment = :production # or :development
  config.timeout = 30              # seconds
  config.retry_attempts = 3
  config.logger = Logger.new(STDOUT)
end
```

## Usage Examples

### Basic Usage

```ruby
# Initialize the gateway
gateway = UnifiedPaymentGateway::Gateway.new

# Create a PIX payment (KAMONEY)
pix_payment = gateway.create_payment(
  provider: :kamoney,
  amount: 100.00,
  description: "Payment for services",
  external_id: "order-123"
)

# Create a cryptocurrency payment (NOWPayments)
crypto_payment = gateway.create_payment(
  provider: :nowpayments,
  price_amount: 100.00,
  price_currency: "usd",
  pay_currency: "btc"
)
```

### KAMONEY (PIX Payments)

#### Receive PIX Payments

```ruby
# Create a PIX payment
response = gateway.kamoney_pix_payment(
  amount: 150.00,
  description: "Product purchase",
  external_id: "order-456"
)

# Access payment details
qr_code = response['data']['qr_code']
pix_key = response['data']['pix_key']
transaction_id = response['data']['transaction_id']
```

#### Send PIX Payments

```ruby
# Send a PIX transfer (new method with parsed response)
response = gateway.send_kamoney_pix_payment(
  amount: 50.00,
  pix_key: "recipient@example.com",
  description: "Refund payment",
  external_id: "transfer-123"
)

# Access transfer details
transfer_id = response[:transfer_id]
status = response[:status]
amount = response[:amount]
pix_key = response[:pix_key]

# Alternative method (returns raw API response)
response = gateway.kamoney_pix_transfer(
  amount: 50.00,
  pix_key: "recipient@example.com",
  description: "Refund payment"
)
```

#### Check Payment Status

```ruby
# Get PIX payment status
status = gateway.get_payment_status(:kamoney, transaction_id)
payment_status = status['data']['status']
```

#### Check Balance

```ruby
# Get wallet balance
balance = gateway.get_balance(:kamoney)
available = balance['data']['available_balance']
pending = balance['data']['pending_balance']
```

### NOWPayments (Cryptocurrency)

#### Create Crypto Payment

```ruby
# Create a cryptocurrency payment
response = gateway.nowpayments_crypto_payment(
  price_amount: 200.00,
  price_currency: "usd",
  pay_currency: "eth",
  ipn_callback_url: "https://your-app.com/webhook"
)

# Access payment details
payment_id = response['payment_id']
pay_address = response['pay_address']
pay_amount = response['pay_amount']
```

#### Create Crypto Payout

```ruby
# Send cryptocurrency to an address
response = gateway.nowpayments_crypto_payout(
  address: "0x742d35Cc6634C0532925a3b8D0f7b2D9e8c78f3b",
  amount: 0.5,
  currency: "eth"
)
```

#### Check API Status and Currencies

```ruby
# Check API status
status = gateway.nowpayments.get_status

# Get supported currencies
currencies = gateway.nowpayments.get_currencies
available_currencies = currencies['currencies']

# Get minimum payment amount
min_amount = gateway.nowpayments.get_minimum_amount("usd", "btc")
minimum_btc = min_amount['minimum_amount']
```

### Unified Interface

The gateway provides a unified interface that automatically routes to the appropriate provider:

```ruby
# Create payment (routes to appropriate provider)
payment = gateway.create_payment(
  provider: :kamoney,  # or :nowpayments
  amount: 100.00,
  # ... other parameters
)

# Create payout (routes to appropriate provider)
payout = gateway.create_payout(
  provider: :kamoney,  # or :nowpayments
  amount: 50.00,
  # ... other parameters
)

# Get payment status (works with both providers)
status = gateway.get_payment_status(provider, payment_id)

# Get balance (works with both providers)
balance = gateway.get_balance(provider)
```

## Error Handling

The gem provides comprehensive error handling with specific error types:

```ruby
begin
  payment = gateway.create_payment(provider: :kamoney, amount: 100.00)
rescue UnifiedPaymentGateway::ConfigurationError => e
  # Handle missing API credentials
  puts "Configuration error: #{e.message}"
rescue UnifiedPaymentGateway::ValidationError => e
  # Handle invalid parameters
  puts "Validation error: #{e.message}"
rescue UnifiedPaymentGateway::NetworkError => e
  # Handle network connectivity issues
  puts "Network error: #{e.message}"
rescue UnifiedPaymentGateway::APIError => e
  # Handle API errors
  puts "API error: #{e.message}"
rescue UnifiedPaymentGateway::RateLimitError => e
  # Handle rate limiting
  puts "Rate limit exceeded: #{e.message}"
end
```

### Available Error Classes

- `UnifiedPaymentGateway::PaymentGatewayError` - Base error class
- `UnifiedPaymentGateway::ConfigurationError` - Configuration issues
- `UnifiedPaymentGateway::APIError` - API-related errors
- `UnifiedPaymentGateway::NetworkError` - Network connectivity issues
- `UnifiedPaymentGateway::ValidationError` - Parameter validation errors
- `UnifiedPaymentGateway::PaymentNotFoundError` - Payment not found
- `UnifiedPaymentGateway::InsufficientFundsError` - Insufficient funds
- `UnifiedPaymentGateway::InvalidCurrencyError` - Invalid currency
- `UnifiedPaymentGateway::RateLimitError` - Rate limit exceeded

## Logging

The gem includes built-in logging capabilities:

```ruby
# Configure logger
UnifiedPaymentGateway.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

# The gem will automatically log:
# - API requests and responses
# - Errors and exceptions
# - Retry attempts
# - Authentication details
```

## Testing

The gem includes a comprehensive RSpec test suite:

```bash
# Run all tests
bundle exec rspec

# Run tests with coverage report
bundle exec rake coverage

# Run code quality checks
bundle exec rake quality
```

## API Reference

### Gateway Methods

#### `create_payment(params)`
Creates a payment with the specified provider.

**Parameters:**
- `provider` (Symbol): `:kamoney` or `:nowpayments`
- Additional provider-specific parameters

**Returns:** Provider-specific response hash

#### `create_payout(params)`
Creates a payout/transfer with the specified provider.

**Parameters:**
- `provider` (Symbol): `:kamoney` or `:nowpayments`
- Additional provider-specific parameters

**Returns:** Provider-specific response hash

#### `get_payment_status(provider, payment_id)`
Gets the status of a payment.

**Parameters:**
- `provider` (Symbol): `:kamoney` or `:nowpayments`
- `payment_id` (String): Payment identifier

**Returns:** Provider-specific response hash

#### `get_balance(provider)`
Gets the account balance for the specified provider.

**Parameters:**
- `provider` (Symbol): `:kamoney` or `:nowpayments`

**Returns:** Provider-specific response hash

### Provider-Specific Methods

#### KAMONEY Methods

- `kamoney_pix_payment(params)` - Create PIX payment
- `kamoney_pix_transfer(params)` - Send PIX transfer (raw response)
- `send_kamoney_pix_payment(params)` - Send PIX transfer (parsed response)
- `kamoney.get_balance` - Get wallet balance
- `kamoney.create_order(params)` - Create order
- `kamoney.get_order(order_id)` - Get order details
- `kamoney.list_transactions` - List transactions

#### NOWPayments Methods

- `nowpayments_crypto_payment(params)` - Create crypto payment
- `nowpayments_crypto_payout(params)` - Send crypto payout
- `nowpayments.get_status` - Check API status
- `nowpayments.get_balance` - Get account balance
- `nowpayments.get_currencies` - Get supported currencies
- `nowpayments.get_minimum_amount(from, to)` - Get minimum amount
- `nowpayments.get_estimated_price(amount, from, to)` - Get price estimate

## Development

After checking out the repo, run:

```bash
bundle install
bundle exec rspec
```

To install this gem onto your local machine, run:

```bash
bundle exec rake install
```

To release a new version:

1. Update the version number in `lib/unified_payment_gateway/version.rb`
2. Run `bundle exec rake release`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

For support and questions:

- Check the [documentation](https://github.com/kleeedolinux/upg-gem)
- Open an [issue](https://github.com/kleeedolinux/upg-gem/issues)
- Contact: kleeedolinux@gmail.com

## Changelog

### Version 1.0.0
- Initial release
- KAMONEY PIX payment integration
- NOWPayments cryptocurrency integration
- Unified payment interface
- Comprehensive error handling
- Full test coverage