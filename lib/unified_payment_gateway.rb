# frozen_string_literal: true

require_relative "unified_payment_gateway/version"
require_relative "unified_payment_gateway/configuration"
require_relative "unified_payment_gateway/errors"
require_relative "unified_payment_gateway/logger"
require_relative "unified_payment_gateway/base_client"
require_relative "unified_payment_gateway/kamoney/client"
require_relative "unified_payment_gateway/nowpayments/client"
require_relative "unified_payment_gateway/gateway"

module UnifiedPaymentGateway
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset
      @configuration = Configuration.new
    end
  end
end