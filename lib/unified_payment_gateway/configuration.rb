# frozen_string_literal: true

module UnifiedPaymentGateway
  class Configuration
    attr_accessor :kamoney_public_key, :kamoney_secret_key, :kamoney_base_url,
                  :nowpayments_api_key, :nowpayments_base_url,
                  :environment, :logger, :timeout, :retry_attempts

    def initialize
      @kamoney_base_url = "https://api2.kamoney.com.br/v2"
      @nowpayments_base_url = "https://api.nowpayments.io/v1"
      @environment = :development
      @logger = nil
      @timeout = 30
      @retry_attempts = 3
    end

    def production?
      @environment == :production
    end

    def development?
      @environment == :development
    end

    def validate!
      errors = []
      
      if kamoney_public_key.nil? || kamoney_public_key.empty?
        errors << "KAMONEY public key is required"
      end
      
      if kamoney_secret_key.nil? || kamoney_secret_key.empty?
        errors << "KAMONEY secret key is required"
      end
      
      if nowpayments_api_key.nil? || nowpayments_api_key.empty?
        errors << "NOWPayments API key is required"
      end
      
      raise ConfigurationError, errors.join(", ") unless errors.empty?
    end
  end
end