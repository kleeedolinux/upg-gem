# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway do
  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(UnifiedPaymentGateway::Configuration)
    end

    it "returns the same instance on subsequent calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      described_class.configure do |config|
        config.kamoney_public_key = "test_public_key"
        config.kamoney_secret_key = "test_secret_key"
        config.nowpayments_api_key = "test_api_key"
      end

      config = described_class.configuration
      expect(config.kamoney_public_key).to eq("test_public_key")
      expect(config.kamoney_secret_key).to eq("test_secret_key")
      expect(config.nowpayments_api_key).to eq("test_api_key")
    end
  end

  describe ".reset" do
    it "resets the configuration" do
      described_class.configure do |config|
        config.kamoney_public_key = "test_key"
      end

      described_class.reset
      config = described_class.configuration
      expect(config.kamoney_public_key).to be_nil
    end
  end
end