# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway::Kamoney::Client do
  let(:public_key) { "test_public_key" }
  let(:secret_key) { "test_secret_key" }
  let(:client) { described_class.new(public_key: public_key, secret_key: secret_key) }

  describe "#initialize" do
    it "sets public_key" do
      expect(client.public_key).to eq(public_key)
    end

    it "sets secret_key" do
      expect(client.secret_key).to eq(secret_key)
    end

    it "sets base_url to KAMONEY API endpoint" do
      expect(client.base_url).to eq("https://api2.kamoney.com.br/v2")
    end
  end

  describe "#create_pix_payment" do
    let(:payment_params) do
      {
        amount: 100.00,
        pix_key: "test@example.com",
        description: "Test payment",
        external_id: "test-123"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "transaction_id" => "txn-123",
          "qr_code" => "qrcode-data",
          "pix_key" => "pix-key-123"
        }
      }
    end

    before do
      stub_request(:post, "https://api2.kamoney.com.br/private/order")
        .with(
          body: hash_including(
            amount: 100.0,
            pix_key: "test@example.com",
            service: "pix",
            description: "Test payment",
            external_id: "test-123"
          )
        )
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates a PIX payment" do
      response = client.create_pix_payment(**payment_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#send_pix_payment" do
    let(:transfer_params) do
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

    before do
      stub_request(:post, "https://api2.kamoney.com.br/private/order")
        .with(
          body: hash_including(
            amount: 100.0,
            pix_key: "recipient@example.com",
            service: "direct_transfers",
            description: "PIX transfer",
            external_id: "transfer-123"
          )
        )
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "sends a PIX payment" do
      response = client.send_pix_payment(**transfer_params)
      expect(response).to eq(response_body)
    end
  end



  describe "#get_wallet_balance" do
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
      stub_request(:get, "https://api2.kamoney.com.br/private/wallet")
        .with(query: hash_including({}))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets wallet balance" do
      response = client.get_wallet_balance
      expect(response).to eq(response_body)
    end
  end

  describe "#create_order" do
    let(:order_params) do
      {
        amount: 150.00,
        service: "test_service",
        description: "Test order",
        external_id: "order-123"
      }
    end
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "order_id" => "order-456",
          "status" => "pending"
        }
      }
    end

    before do
      stub_request(:post, "https://api2.kamoney.com.br/private/order")
        .with(body: hash_including(
          amount: 150.0,
          service: "test_service",
          description: "Test order",
          external_id: "order-123"
        ))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates an order" do
      response = client.create_order(**order_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_order" do
    let(:order_id) { "order-123" }
    let(:response_body) do
      {
        "success" => true,
        "data" => {
          "order_id" => order_id,
          "status" => "completed"
        }
      }
    end

    before do
      stub_request(:get, "https://api2.kamoney.com.br/private/order/#{order_id}")
        .with(query: hash_including({}))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets order details" do
      response = client.get_order(id: order_id)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_wallet_statement" do
    let(:response_body) do
      {
        "success" => true,
        "data" => [
          {
            "transaction_id" => "txn-1",
            "amount" => 100.00,
            "status" => "completed",
            "type" => "deposit",
            "created_at" => "2024-01-01T00:00:00Z"
          },
          {
            "transaction_id" => "txn-2",
            "amount" => 50.00,
            "status" => "pending",
            "type" => "withdrawal",
            "created_at" => "2024-01-02T00:00:00Z"
          }
        ],
        "pagination" => {
          "page" => 1,
          "limit" => 50,
          "total" => 2
        }
      }
    end

    before do
      stub_request(:get, "https://api2.kamoney.com.br/private/wallet/statement")
        .with(query: hash_including({ page: "1", limit: "50" }))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets wallet statement" do
      response = client.get_wallet_statement(page: 1, limit: 50)
      expect(response).to eq(response_body)
    end
  end



  # New KAMONEY client method tests
  describe "#get_withdrawals_list" do
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
      stub_request(:get, "https://api2.kamoney.com.br/private/withdrawals")
        .with(query: hash_including({ page: "1", limit: "50" }))  # Allow specified parameters plus any others (like nonce)
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets withdrawals list" do
      response = client.get_withdrawals_list(page: 1, limit: 50)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_crypto_withdrawal" do
    let(:withdrawal_params) do
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
      stub_request(:post, "https://api2.kamoney.com.br/private/withdrawal")
        .with(body: hash_including(
          amount: 0.001,
          service: "crypto_withdrawal",
          crypto_currency: "BTC",
          wallet_address: "bc1q123..."
        ))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates crypto withdrawal" do
      response = client.create_crypto_withdrawal(**withdrawal_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_pix_to_crypto_conversion" do
    let(:conversion_params) do
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
      stub_request(:post, "https://api2.kamoney.com.br/private/order")
        .with(body: hash_including(
          amount: 100.0,
          pix_key: "test@example.com",
          service: "pix_crypto_conversion",
          target_crypto: "BTC",
          wallet_address: "bc1q123..."
        ))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates PIX to crypto conversion" do
      response = client.create_pix_to_crypto_conversion(**conversion_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_crypto_deposit_address" do
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
      stub_request(:get, "https://api2.kamoney.com.br/private/wallet/deposit/BTC")
        .with(query: hash_including({}))  # Allow any query parameters (including nonce)
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets crypto deposit address" do
      response = client.get_crypto_deposit_address(crypto_currency: crypto_currency)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_exchange_rates" do
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
      stub_request(:get, "https://api2.kamoney.com.br/private/exchange/rates")
        .with(query: hash_including({ base: "BRL" }))  # Allow base parameter plus any others (like nonce)
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "gets exchange rates" do
      response = client.get_exchange_rates(base_currency: "BRL")
      expect(response).to eq(response_body)
    end
  end

  describe "#create_exchange_swap" do
    let(:swap_params) do
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
      stub_request(:post, "https://api2.kamoney.com.br/private/exchange/swap")
        .with(body: hash_including(
          from_amount: 100.0,
          from_currency: "BRL",
          to_currency: "BTC"
        ))
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end

    it "creates exchange swap" do
      response = client.create_exchange_swap(**swap_params)
      expect(response).to eq(response_body)
    end
  end
end