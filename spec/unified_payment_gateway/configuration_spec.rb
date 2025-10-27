# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway::Configuration do
  subject(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.kamoney_base_url).to eq("https://api2.kamoney.com.br/v2")
      expect(config.nowpayments_base_url).to eq("https://api.nowpayments.io/v1")
      expect(config.environment).to eq(:development)
      expect(config.timeout).to eq(30)
      expect(config.retry_attempts).to eq(3)
    end
  end

  describe "#production?" do
    it "returns true when environment is production" do
      config.environment = :production
      expect(config.production?).to be true
    end

    it "returns false when environment is not production" do
      config.environment = :development
      expect(config.production?).to be false
    end
  end

  describe "#development?" do
    it "returns true when environment is development" do
      config.environment = :development
      expect(config.development?).to be true
    end

    it "returns false when environment is not development" do
      config.environment = :production
      expect(config.development?).to be false
    end
  end

  describe "#validate!" do
    context "when all required keys are present" do
      before do
        config.kamoney_public_key = "test_public_key"
        config.kamoney_secret_key = "test_secret_key"
        config.nowpayments_api_key = "test_api_key"
      end

      it "does not raise an error" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when kamoney_public_key is missing" do
      before do
        config.kamoney_secret_key = "test_secret_key"
        config.nowpayments_api_key = "test_api_key"
      end

      it "raises ConfigurationError" do
        expect { config.validate! }.to raise_error(
          UnifiedPaymentGateway::ConfigurationError,
          /KAMONEY public key is required/
        )
      end
    end

    context "when kamoney_secret_key is missing" do
      before do
        config.kamoney_public_key = "test_public_key"
        config.nowpayments_api_key = "test_api_key"
      end

      it "raises ConfigurationError" do
        expect { config.validate! }.to raise_error(
          UnifiedPaymentGateway::ConfigurationError,
          /KAMONEY secret key is required/
        )
      end
    end

    context "when nowpayments_api_key is missing" do
      before do
        config.kamoney_public_key = "test_public_key"
        config.kamoney_secret_key = "test_secret_key"
      end

      it "raises ConfigurationError" do
        expect { config.validate! }.to raise_error(
          UnifiedPaymentGateway::ConfigurationError,
          /NOWPayments API key is required/
        )
      end
    end

    context "when multiple keys are missing" do
      it "raises ConfigurationError with all missing keys" do
        expect { config.validate! }.to raise_error(
          UnifiedPaymentGateway::ConfigurationError,
          /KAMONEY public key is required.*KAMONEY secret key is required.*NOWPayments API key is required/
        )
      end
    end
  end
end