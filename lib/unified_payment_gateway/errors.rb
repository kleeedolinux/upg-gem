# frozen_string_literal: true

module UnifiedPaymentGateway
  class PaymentGatewayError < StandardError; end
  class ConfigurationError < PaymentGatewayError; end
  class AuthenticationError < PaymentGatewayError; end
  class APIError < PaymentGatewayError; end
  class NetworkError < PaymentGatewayError; end
  class ValidationError < PaymentGatewayError; end
  class PaymentNotFoundError < PaymentGatewayError; end
  class InsufficientFundsError < PaymentGatewayError; end
  class InvalidCurrencyError < PaymentGatewayError; end
  class RateLimitError < PaymentGatewayError; end
end