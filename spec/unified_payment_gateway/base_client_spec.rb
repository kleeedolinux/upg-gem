# frozen_string_literal: true

require "spec_helper"

RSpec.describe UnifiedPaymentGateway::BaseClient do
  let(:base_url) { "https://api.example.com" }
  let(:client) { described_class.new(base_url: base_url) }

  describe "#initialize" do
    it "sets base_url" do
      expect(client.base_url).to eq(base_url)
    end

    it "sets default timeout" do
      expect(client.timeout).to eq(30)
    end

    it "sets default retry_attempts" do
      expect(client.retry_attempts).to eq(3)
    end

    it "sets logger" do
      expect(client.logger).to be_a(UnifiedPaymentGateway::Logger)
    end
  end

  describe "#get" do
    let(:path) { "/test" }
    let(:response_body) { { "message" => "success" } }

    before do
      stub_request(:get, "#{base_url}#{path}")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "makes GET request" do
      response = client.get(path)
      expect(response).to eq(response_body)
    end

    it "includes default headers" do
      client.get(path)
      
      expect(a_request(:get, "#{base_url}#{path}")
        .with(headers: {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "User-Agent" => /UnifiedPaymentGateway/
        })).to have_been_made
    end

    it "merges custom headers" do
      custom_headers = { "X-Custom" => "value" }
      client.get(path, {}, custom_headers)
      
      expect(a_request(:get, "#{base_url}#{path}")
        .with(headers: hash_including("X-Custom" => "value"))).to have_been_made
    end
  end

  describe "#post" do
    let(:path) { "/test" }
    let(:request_body) { { "key" => "value" } }
    let(:response_body) { { "message" => "created" } }

    before do
      stub_request(:post, "#{base_url}#{path}")
        .with(body: request_body.to_json)
        .to_return(status: 201, body: response_body.to_json)
    end

    it "makes POST request with JSON body" do
      response = client.post(path, request_body)
      expect(response).to eq(response_body)
    end
  end

  describe "#put" do
    let(:path) { "/test/1" }
    let(:request_body) { { "key" => "updated_value" } }
    let(:response_body) { { "message" => "updated" } }

    before do
      stub_request(:put, "#{base_url}#{path}")
        .with(body: request_body.to_json)
        .to_return(status: 200, body: response_body.to_json)
    end

    it "makes PUT request with JSON body" do
      response = client.put(path, request_body)
      expect(response).to eq(response_body)
    end
  end

  describe "#delete" do
    let(:path) { "/test/1" }
    let(:response_body) { { "message" => "deleted" } }

    before do
      stub_request(:delete, "#{base_url}#{path}")
        .to_return(status: 200, body: response_body.to_json)
    end

    it "makes DELETE request" do
      response = client.delete(path)
      expect(response).to eq(response_body)
    end
  end

  describe "error handling" do
    context "when 400 error" do
      before do
        stub_request(:get, "#{base_url}/bad-request")
          .to_return(status: 400, body: { "error" => "Bad request" }.to_json)
      end

      it "raises ValidationError" do
        expect { client.get("/bad-request") }
          .to raise_error(UnifiedPaymentGateway::ValidationError, "Bad request")
      end
    end

    context "when 401 error" do
      before do
        stub_request(:get, "#{base_url}/unauthorized")
          .to_return(status: 401)
      end

      it "raises AuthenticationError" do
        expect { client.get("/unauthorized") }
          .to raise_error(UnifiedPaymentGateway::AuthenticationError, "Invalid credentials")
      end
    end

    context "when 404 error" do
      before do
        stub_request(:get, "#{base_url}/not-found")
          .to_return(status: 404)
      end

      it "raises PaymentNotFoundError" do
        expect { client.get("/not-found") }
          .to raise_error(UnifiedPaymentGateway::PaymentNotFoundError, "Resource not found")
      end
    end

    context "when 429 error" do
      before do
        stub_request(:get, "#{base_url}/rate-limit")
          .to_return(status: 429)
      end

      it "raises RateLimitError" do
        expect { client.get("/rate-limit") }
          .to raise_error(UnifiedPaymentGateway::RateLimitError, "Rate limit exceeded")
      end
    end

    context "when 500 error" do
      before do
        stub_request(:get, "#{base_url}/server-error")
          .to_return(status: 500)
      end

      it "raises APIError" do
        expect { client.get("/server-error") }
          .to raise_error(UnifiedPaymentGateway::APIError, "Server error: 500")
      end
    end

    context "when timeout error" do
      before do
        stub_request(:get, "#{base_url}/timeout")
          .to_timeout
      end

      it "raises NetworkError" do
        expect { client.get("/timeout") }
          .to raise_error(UnifiedPaymentGateway::NetworkError, /Request timeout/)
      end
    end

    context "when connection failed" do
      before do
        stub_request(:get, "#{base_url}/connection-failed")
          .to_raise(Faraday::ConnectionFailed.new("Connection failed"))
      end

      it "raises NetworkError" do
        expect { client.get("/connection-failed") }
          .to raise_error(UnifiedPaymentGateway::NetworkError, /Connection failed/)
      end
    end
  end

  describe "retry logic" do
    let(:path) { "/retry-test" }
    let(:attempts) { [] }

    before do
      stub_request(:get, "#{base_url}#{path}")
        .to_return do |request|
          attempts << request
          if attempts.size < 2
            { status: 500 }
          else
            { status: 200, body: { "message" => "success" }.to_json }
          end
        end
    end

    it "retries failed requests" do
      response = client.get(path)
      expect(response).to eq({ "message" => "success" })
      expect(attempts.size).to eq(2)
    end
  end
end