# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway::Nowpayments::Client do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key: api_key) }

  describe "#initialize" do
    it "sets api_key" do
      expect(client.api_key).to eq(api_key)
    end

    it "sets base_url to NOWPayments API endpoint" do
      expect(client.base_url).to eq("https://api.nowpayments.io/v1")
    end
  end

  describe "#get_status" do
    let(:response_body) do
      {
        "message" => "OK"
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/status")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets API status" do
      response = client.get_status
      expect(response).to eq(response_body)
    end

    it "includes API key in headers" do
      response = client.get_status
      
      expect(a_request(:get, "https://api.nowpayments.io/v1/status")
        .with(headers: { "x-api-key" => api_key })).to have_been_made
    end
  end

  describe "#get_balance" do
    let(:response_body) do
      {
        "available_balance" => 1000.50,
        "pending_balance" => 200.25
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/balance")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets account balance" do
      response = client.get_balance
      expect(response).to eq(response_body)
    end
  end

  describe "#get_currencies" do
    let(:response_body) do
      {
        "currencies" => ["btc", "eth", "usdt", "usdc"]
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/currencies")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets supported currencies" do
      response = client.get_currencies
      expect(response).to eq(response_body)
    end
  end

  describe "#get_minimum_amount" do
    let(:currency_from) { "btc" }
    let(:currency_to) { "usdt" }
    let(:response_body) do
      {
        "minimum_amount" => 0.001
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/min-amount")
        .with(query: { currency_from: currency_from, currency_to: currency_to })
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets minimum amount for currency pair" do
      response = client.get_minimum_amount(currency_from, currency_to)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_estimated_price" do
    let(:amount) { 1.0 }
    let(:currency_from) { "btc" }
    let(:currency_to) { "usdt" }
    let(:response_body) do
      {
        "estimated_amount" => 45000.50
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/estimate")
        .with(query: { amount: amount, currency_from: currency_from, currency_to: currency_to })
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets estimated price for currency conversion" do
      response = client.get_estimated_price(amount, currency_from, currency_to)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_payment" do
    let(:payment_params) do
      {
        price_amount: 100.00,
        price_currency: "usd",
        pay_currency: "btc",
        pay_amount: 0.002,
        ipn_callback_url: "https://example.com/webhook"
      }
    end
    let(:response_body) do
      {
        "payment_id" => "pay-123",
        "payment_status" => "waiting",
        "pay_address" => "bc1q123...",
        "pay_amount" => 0.002,
        "pay_currency" => "btc"
      }
    end

    before do
      stub_request(:post, "https://api.nowpayments.io/v1/payment")
        .with(body: payment_params.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates a payment" do
      response = client.create_payment(payment_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#create_invoice" do
    let(:invoice_params) do
      {
        price_amount: 200.00,
        price_currency: "usd",
        order_id: "order-123",
        order_description: "Test order"
      }
    end
    let(:response_body) do
      {
        "id" => "inv-123",
        "invoice_url" => "https://nowpayments.io/payment/inv-123"
      }
    end

    before do
      stub_request(:post, "https://api.nowpayments.io/v1/invoice")
        .with(body: invoice_params.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates an invoice" do
      response = client.create_invoice(invoice_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_payment_status" do
    let(:payment_id) { "pay-123" }
    let(:response_body) do
      {
        "payment_id" => payment_id,
        "payment_status" => "finished",
        "pay_address" => "bc1q123...",
        "price_amount" => 100.00,
        "price_currency" => "usd"
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/payment/#{payment_id}")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets payment status" do
      response = client.get_payment_status(payment_id)
      expect(response).to eq(response_body)
    end
  end

  describe "#list_payments" do
    let(:response_body) do
      {
        "data" => [
          {
            "payment_id" => "pay-123",
            "payment_status" => "finished",
            "pay_amount" => 0.001,
            "pay_currency" => "btc"
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/payment")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "lists payments" do
      response = client.list_payments
      expect(response).to eq(response_body)
    end
  end

  describe "#create_payout" do
    let(:payout_params) do
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
      stub_request(:post, "https://api.nowpayments.io/v1/payout")
        .with(body: payout_params.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates a payout" do
      response = client.create_payout(payout_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#verify_payout" do
    let(:payout_id) { "payout-123" }
    let(:verification_code) { "123456" }
    let(:response_body) do
      {
        "id" => payout_id,
        "status" => "finished"
      }
    end

    before do
      stub_request(:post, "https://api.nowpayments.io/v1/payout/verify")
        .with(body: { id: payout_id, verification_code: verification_code }.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "verifies a payout" do
      response = client.verify_payout(payout_id, verification_code)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_payout_status" do
    let(:payout_id) { "payout-123" }
    let(:response_body) do
      {
        "id" => payout_id,
        "status" => "finished",
        "amount" => 0.001,
        "currency" => "btc"
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/payout/#{payout_id}")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets payout status" do
      response = client.get_payout_status(payout_id)
      expect(response).to eq(response_body)
    end
  end

  describe "#list_payouts" do
    let(:response_body) do
      {
        "data" => [
          {
            "id" => "payout-123",
            "status" => "finished",
            "amount" => 0.001,
            "currency" => "btc"
          }
        ]
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/payout")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "lists payouts" do
      response = client.list_payouts
      expect(response).to eq(response_body)
    end
  end

  # New NOWPayments client method tests
  describe "#create_mass_payout" do
    let(:mass_payout_params) do
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
      stub_request(:post, "https://api.nowpayments.io/v1/mass-payout")
        .with(body: mass_payout_params.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "creates mass payout" do
      response = client.create_mass_payout(**mass_payout_params)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_mass_payout_status" do
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
      stub_request(:get, "https://api.nowpayments.io/v1/mass-payout/#{batch_id}")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets mass payout status" do
      response = client.get_mass_payout_status(batch_id: batch_id)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_mass_payouts_list" do
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
      stub_request(:get, "https://api.nowpayments.io/v1/mass-payout")
        .with(query: { page: 1, limit: 50 })
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets mass payouts list" do
      response = client.get_mass_payouts_list(page: 1, limit: 50)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_payout_limits" do
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
      stub_request(:get, "https://api.nowpayments.io/v1/payout/limits")
        .with(query: { currency: currency })
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets payout limits" do
      response = client.get_payout_limits(currency: currency)
      expect(response).to eq(response_body)
    end
  end

  describe "#validate_payout_address" do
    let(:address) { "bc1q123..." }
    let(:currency) { "BTC" }
    let(:response_body) do
      {
        "address" => address,
        "currency" => currency,
        "valid" => true,
        "network" => "bitcoin"
      }
    end

    before do
      stub_request(:get, "https://api.nowpayments.io/v1/payout/validate")
        .with(query: { address: address, currency: currency })
        .to_return(status: 200, body: response_body.to_json)
    end

    it "validates payout address" do
      response = client.validate_payout_address(address: address, currency: currency)
      expect(response).to eq(response_body)
    end
  end

  describe "#get_available_payout_currencies" do
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
      stub_request(:get, "https://api.nowpayments.io/v1/payout/currencies")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "gets available payout currencies" do
      response = client.get_available_payout_currencies()
      expect(response).to eq(response_body)
    end
  end
end