# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway::Gateway do
  let(:gateway) { described_class.new }

  before do
    UnifiedPaymentGateway.configure do |config|
      config.kamoney_public_key = "test_public_key"
      config.kamoney_secret_key = "test_secret_key"
      config.nowpayments_api_key = "test_api_key"
    end
  end

  after do
    UnifiedPaymentGateway.reset
  end

  describe "#initialize" do
    it "initializes kamoney client" do
      expect(gateway.kamoney).to be_a(UnifiedPaymentGateway::Kamoney::Client)
    end

    it "initializes nowpayments client" do
      expect(gateway.nowpayments).to be_a(UnifiedPaymentGateway::Nowpayments::Client)
    end
  end

  describe "#create_payment" do
    context "with kamoney provider" do
      let(:payment_params) do
        {
          provider: :kamoney,
          amount: 100.00,
          description: "Test payment",
          external_id: "test-123"
        }
      end
      let(:response_body) do
        {
          "success" => true,
          "data" => {
            "transaction_id" => "txn-123",
            "qr_code" => "qrcode-data"
          }
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
          .to receive(:create_pix_payment)
          .and_return(response_body)
      end

      it "creates payment with kamoney" do
        response = gateway.create_payment(payment_params)
        expect(response).to eq(response_body)
      end
    end

    context "with nowpayments provider" do
      let(:payment_params) do
        {
          provider: :nowpayments,
          price_amount: 100.00,
          price_currency: "usd",
          pay_currency: "btc"
        }
      end
      let(:response_body) do
        {
          "payment_id" => "pay-123",
          "payment_status" => "waiting",
          "pay_address" => "bc1q123..."
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
          .to receive(:create_payment)
          .and_return(response_body)
      end

      it "creates payment with nowpayments" do
        response = gateway.create_payment(payment_params)
        expect(response).to eq(response_body)
      end
    end

    context "with invalid provider" do
      let(:payment_params) { { provider: :invalid } }

      it "raises ArgumentError" do
        expect { gateway.create_payment(payment_params) }
          .to raise_error(ArgumentError, "Invalid provider: invalid")
      end
    end
  end

  describe "#create_payout" do
    context "with kamoney provider" do
      let(:payout_params) do
        {
          provider: :kamoney,
          amount: 50.00,
          pix_key: "recipient@example.com",
          description: "Test transfer"
        }
      end
      let(:response_body) do
        {
          "success" => true,
          "data" => {
            "transaction_id" => "txn-456",
            "status" => "processing"
          }
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
          .to receive(:send_pix_payment)
          .and_return(response_body)
      end

      it "creates payout with kamoney" do
        response = gateway.create_payout(payout_params)
        expect(response).to eq(response_body)
      end
    end

    context "with nowpayments provider" do
      let(:payout_params) do
        {
          provider: :nowpayments,
          address: "bc1q123...",
          amount: 0.001,
          currency: "btc"
        }
      end
      let(:response_body) do
        {
          "id" => "payout-123",
          "status" => "processing"
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
          .to receive(:create_payout)
          .and_return(response_body)
      end

      it "creates payout with nowpayments" do
        response = gateway.create_payout(payout_params)
        expect(response).to eq(response_body)
      end
    end
  end

  describe "#get_payment_status" do
    context "with kamoney provider" do
      let(:transaction_id) { "txn-123" }
      let(:response_body) do
        {
          "success" => true,
          "data" => {
            "transaction_id" => transaction_id,
            "status" => "paid"
          }
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
          .to receive(:get_pix_payment_status)
          .and_return(response_body)
      end

      it "gets payment status from kamoney" do
        response = gateway.get_payment_status(:kamoney, transaction_id)
        expect(response).to eq(response_body)
      end
    end

    context "with nowpayments provider" do
      let(:payment_id) { "pay-123" }
      let(:response_body) do
        {
          "payment_id" => payment_id,
          "payment_status" => "finished"
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
          .to receive(:get_payment_status)
          .and_return(response_body)
      end

      it "gets payment status from nowpayments" do
        response = gateway.get_payment_status(:nowpayments, payment_id)
        expect(response).to eq(response_body)
      end
    end
  end

  describe "#get_balance" do
    context "with kamoney provider" do
      let(:response_body) do
        {
          "success" => true,
          "data" => {
            "available_balance" => 1000.00,
            "pending_balance" => 200.00
          }
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
          .to receive(:get_balance)
          .and_return(response_body)
      end

      it "gets balance from kamoney" do
        response = gateway.get_balance(:kamoney)
        expect(response).to eq(response_body)
      end
    end

    context "with nowpayments provider" do
      let(:response_body) do
        {
          "available_balance" => 500.25,
          "pending_balance" => 100.50
        }
      end

      before do
        allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
          .to receive(:get_balance)
          .and_return(response_body)
      end

      it "gets balance from nowpayments" do
        response = gateway.get_balance(:nowpayments)
        expect(response).to eq(response_body)
      end
    end
  end

  describe "#kamoney_pix_payment" do
    let(:params) do
      {
        amount: 100.00,
        description: "Test PIX payment",
        external_id: "test-123"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "transaction_id" => "txn-123",
          "qr_code" => "qrcode-data"
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:create_pix_payment)
        .and_return(response_body)
    end

    it "creates PIX payment through kamoney" do
      response = gateway.kamoney_pix_payment(params)
      expect(response).to eq(response_body)
    end
  end



  describe "#send_kamoney_pix_payment" do
    let(:params) do
      {
        amount: 100.00,
        pix_key: "recipient@example.com",
        description: "PIX transfer",
        external_id: "transfer-123"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "id" => "transfer-123",
          "status" => "processing",
          "amount" => 100.00,
          "pix_key" => "recipient@example.com",
          "created_at" => "2024-01-01T00:00:00Z"
        }
      }
    end
    let(:parsed_response) do
      {
        transfer_id: "transfer-123",
        status: "processing",
        amount: 100.00,
        currency: "BRL",
        pix_key: "recipient@example.com",
        created_at: "2024-01-01T00:00:00Z",
        provider: "kamoney",
        raw_response: response_body
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:send_pix_payment)
        .and_return(response_body)
    end

    it "sends PIX payment through kamoney and parses response" do
      response = gateway.send_kamoney_pix_payment(**params)
      expect(response).to eq(parsed_response)
    end
  end

  describe "#nowpayments_crypto_payment" do
    let(:params) do
      {
        price_amount: 100.00,
        price_currency: "usd",
        pay_currency: "btc"
      }
    end
    let(:response_body) do
      {
        "payment_id" => "pay-123",
        "payment_status" => "waiting",
        "pay_address" => "bc1q123..."
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:create_payment)
        .and_return(response_body)
    end

    it "creates crypto payment through nowpayments" do
      response = gateway.nowpayments_crypto_payment(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#nowpayments_crypto_payout" do
    let(:params) do
      {
        address: "bc1q123...",
        amount: 0.001,
        currency: "btc"
      }
    end
    let(:response_body) do
      {
        "id" => "payout-123",
        "status" => "processing"
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:create_payout)
        .and_return(response_body)
    end

    it "creates crypto payout through nowpayments" do
      response = gateway.nowpayments_crypto_payout(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#parse_response" do
    it "returns data when response is successful" do
      response = { "success" => true, "data" => { "key" => "value" } }
      result = gateway.send(:parse_response, response)
      expect(result).to eq({ "key" => "value" })
    end

    it "raises error when response is not successful" do
      response = { "success" => false, "message" => "Error occurred" }
      expect { gateway.send(:parse_response, response) }
        .to raise_error(UnifiedPaymentGateway::APIError, "Error occurred")
    end
  end

  # New KAMONEY endpoint tests
  describe "#get_kamoney_withdrawals_list" do
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "withdrawals" => [
            {
              "id" => "withdrawal-123",
              "amount" => 100.00,
              "currency" => "BTC",
              "status" => "completed",
              "created_at" => "2024-01-01T00:00:00Z"
            }
          ],
          "pagination" => {
            "page" => 1,
            "limit" => 50,
            "total" => 1
          }
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:get_withdrawals_list)
        .and_return(response_body)
    end

    it "gets withdrawals list from kamoney" do
      response = gateway.get_kamoney_withdrawals_list(page: 1, limit: 50)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_kamoney_crypto_withdrawal" do
    let(:params) do
      {
        amount: 0.001,
        crypto_currency: "BTC",
        wallet_address: "bc1q123...",
        description: "Test crypto withdrawal"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "withdrawal_id" => "withdrawal-123",
          "transaction_hash" => "tx-hash-123",
          "status" => "processing"
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:create_crypto_withdrawal)
        .and_return(response_body)
    end

    it "creates crypto withdrawal through kamoney" do
      response = gateway.create_kamoney_crypto_withdrawal(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_kamoney_pix_to_crypto_conversion" do
    let(:params) do
      {
        amount: 100.00,
        pix_key: "test@example.com",
        target_crypto: "BTC",
        wallet_address: "bc1q123..."
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "conversion_id" => "conv-123",
          "pix_order_id" => "pix-123",
          "crypto_amount" => 0.001,
          "status" => "waiting_payment"
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:create_pix_to_crypto_conversion)
        .and_return(response_body)
    end

    it "creates PIX to crypto conversion through kamoney" do
      response = gateway.create_kamoney_pix_to_crypto_conversion(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_kamoney_crypto_deposit_address" do
    let(:crypto_currency) { "BTC" }
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "currency" => "BTC",
          "address" => "bc1q123...",
          "tag" => nil,
          "network" => "bitcoin"
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:get_crypto_deposit_address)
        .and_return(response_body)
    end

    it "gets crypto deposit address from kamoney" do
      response = gateway.get_kamoney_crypto_deposit_address(crypto_currency: crypto_currency)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_kamoney_exchange_rates" do
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "base_currency" => "BRL",
          "rates" => {
            "BTC" => 0.00001,
            "ETH" => 0.0001,
            "USDT" => 0.20
          }
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:get_exchange_rates)
        .and_return(response_body)
    end

    it "gets exchange rates from kamoney" do
      response = gateway.get_kamoney_exchange_rates(base_currency: "BRL")
      expect(response).to eq(response_body)
    end
  end

  describe "#create_kamoney_exchange_swap" do
    let(:params) do
      {
        from_amount: 100.00,
        from_currency: "BRL",
        to_currency: "BTC"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "swap_id" => "swap-123",
          "from_amount" => 100.00,
          "to_amount" => 0.001,
          "exchange_rate" => 0.00001,
          "status" => "completed"
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Kamoney::Client)
        .to receive(:create_exchange_swap)
        .and_return(response_body)
    end

    it "creates exchange swap through kamoney" do
      response = gateway.create_kamoney_exchange_swap(params)
      expect(response).to eq(response_body)
    end
  end

  # New NOWPayments endpoint tests
  describe "#create_nowpayments_mass_payout" do
    let(:params) do
      {
        withdrawals: [
          {
            address: "bc1q123...",
            amount: 0.001,
            currency: "BTC"
          },
          {
            address: "0x123...",
            amount: 0.01,
            currency: "ETH"
          }
        ],
        ipn_callback_url: "https://example.com/webhook"
      }
    end
    let(:response_body) do
      {
        "batch_id" => "batch-123",
        "status" => "processing",
        "total_withdrawals" => 2,
        "total_amount" => 0.011
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:create_mass_payout)
        .and_return(response_body)
    end

    it "creates mass payout through nowpayments" do
      response = gateway.create_nowpayments_mass_payout(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_nowpayments_mass_payout_status" do
    let(:batch_id) { "batch-123" }
    let(:response_body) do
      {
        "batch_id" => batch_id,
        "status" => "completed",
        "total_withdrawals" => 2,
        "completed_withdrawals" => 2,
        "withdrawals" => [
          {
            "id" => "withdrawal-1",
            "status" => "completed",
            "transaction_hash" => "tx-hash-1"
          }
        ]
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:get_mass_payout_status)
        .and_return(response_body)
    end

    it "gets mass payout status from nowpayments" do
      response = gateway.get_nowpayments_mass_payout_status(batch_id: batch_id)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_nowpayments_mass_payouts_list" do
    let(:response_body) do
      {
        "batches" => [
          {
            "batch_id" => "batch-123",
            "status" => "completed",
            "total_withdrawals" => 2,
            "created_at" => "2024-01-01T00:00:00Z"
          }
        ],
        "pagination" => {
          "page" => 1,
          "limit" => 50,
          "total" => 1
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:get_mass_payouts_list)
        .and_return(response_body)
    end

    it "gets mass payouts list from nowpayments" do
      response = gateway.get_nowpayments_mass_payouts_list(page: 1, limit: 50)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_nowpayments_payout_limits" do
    let(:currency) { "BTC" }
    let(:response_body) do
      {
        "currency" => currency,
        "min_amount" => 0.0005,
        "max_amount" => 10.0,
        "fee_percentage" => 1.0
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:get_payout_limits)
        .and_return(response_body)
    end

    it "gets payout limits from nowpayments" do
      response = gateway.get_nowpayments_payout_limits(currency: currency)
      expect(response).to eq(response_body)
    end
  end

  describe "#validate_nowpayments_payout_address" do
    let(:params) do
      {
        address: "bc1q123...",
        currency: "BTC"
      }
    end
    let(:response_body) do
      {
        "address" => "bc1q123...",
        "currency" => "BTC",
        "valid" => true,
        "network" => "bitcoin"
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:validate_payout_address)
        .and_return(response_body)
    end

    it "validates payout address through nowpayments" do
      response = gateway.validate_nowpayments_payout_address(params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_nowpayments_available_payout_currencies" do
    let(:response_body) do
      {
        "currencies" => ["BTC", "ETH", "USDT", "BNB"],
        "networks" => {
          "BTC" => ["bitcoin"],
          "ETH" => ["ethereum", "arbitrum"],
          "USDT" => ["ethereum", "trc20", "bep20"]
        }
      }
    end

    before do
      allow_any_instance_of(UnifiedPaymentGateway::Nowpayments::Client)
        .to receive(:get_available_payout_currencies)
        .and_return(response_body)
    end

    it "gets available payout currencies from nowpayments" do
      response = gateway.get_nowpayments_available_payout_currencies()
      expect(response).to eq(response_body)
    end
  end

  describe "#determine_kamoney_service" do
    it "returns :pix_payment for payment operations" do
      params = { amount: 100, description: "Test" }
      service = gateway.send(:determine_kamoney_service, params)
      expect(service).to eq(:pix_payment)
    end

    it "returns :pix_transfer for transfer operations" do
      params = { amount: 50, pix_key: "recipient@example.com" }
      service = gateway.send(:determine_kamoney_service, params)
      expect(service).to eq(:pix_transfer)
    end

    it "returns :unknown for unrecognized operations" do
      params = { unknown_param: "value" }
      service = gateway.send(:determine_kamoney_service, params)
      expect(service).to eq(:unknown)
    end
  end
end