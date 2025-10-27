# frozen_string_literal: true

require "openssl"
require "uri"
require "cgi"

module UnifiedPaymentGateway
  module Kamoney
    class Client < BaseClient
      attr_reader :public_key, :secret_key

      def initialize(public_key:, secret_key:, base_url: nil, **options)
        super(base_url: base_url || UnifiedPaymentGateway.configuration.kamoney_base_url, **options)
        @public_key = public_key
        @secret_key = secret_key
      end

      # Public API Methods

      def get_services_order
        get("/public/services/order")
      end

      def get_services_merchant
        get("/public/services/merchant")
      end

      def get_services_buy
        get("/public/services/buy")
      end

      def create_account(email:, terms:, affiliate_code: nil)
        post("/public/register", {
          email: email,
          terms: terms,
          affiliate_code: affiliate_code
        }.compact)
      end

      def activate_account(code:, email:)
        post("/public/active", {
          code: code,
          email: email
        })
      end

      def request_password_reset(email:)
        post("/public/forgot", {
          email: email
        })
      end

      def get_limits(service:)
        get("/public/services/#{service}/limits")
      end

      # Private API Methods

      def create_order(amount:, service:, **options)
        payload = {
          amount: amount,
          service: service
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def get_order(id:)
        get_with_auth("/private/order/#{id}")
      end

      def cancel_order(id:)
        delete_with_auth("/private/order/#{id}")
      end

      def create_pix_payment(amount:, pix_key:, **options)
        payload = {
          amount: amount,
          pix_key: pix_key,
          service: "pix"
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def send_pix_payment(amount:, pix_key:, **options)
        payload = {
          amount: amount,
          pix_key: pix_key,
          service: "direct_transfers"
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def create_bank_transfer(amount:, bank_code:, agency:, account:, account_type:, **options)
        payload = {
          amount: amount,
          bank_code: bank_code,
          agency: agency,
          account: account,
          account_type: account_type,
          service: "direct_transfers"
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def create_payment_slip(amount:, **options)
        payload = {
          amount: amount,
          service: "payment_slips"
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def get_wallet_balance
        get_with_auth("/private/wallet")
      end

      def get_wallet_statement(start_date: nil, end_date: nil, page: 1, limit: 50)
        params = {
          start_date: start_date,
          end_date: end_date,
          page: page,
          limit: limit
        }.compact

        get_with_auth("/private/wallet/statement", params)
      end

      def create_withdrawal(amount:, service:, **options)
        payload = {
          amount: amount,
          service: service
        }.merge(options)

        post_with_auth("/private/withdrawal", payload)
      end

      def get_withdrawal(id:)
        get_with_auth("/private/withdrawal/#{id}")
      end

      def get_withdrawals_list(page: 1, limit: 50, status: nil, start_date: nil, end_date: nil)
        params = {
          page: page,
          limit: limit,
          status: status,
          start_date: start_date,
          end_date: end_date
        }.compact

        get_with_auth("/private/withdrawals", params)
      end

      def create_crypto_withdrawal(amount:, crypto_currency:, wallet_address:, **options)
        payload = {
          amount: amount,
          service: "crypto_withdrawal",
          crypto_currency: crypto_currency,
          wallet_address: wallet_address
        }.merge(options)

        post_with_auth("/private/withdrawal", payload)
      end

      def create_pix_to_crypto_conversion(amount:, pix_key:, target_crypto:, wallet_address:, **options)
        payload = {
          amount: amount,
          pix_key: pix_key,
          service: "pix_crypto_conversion",
          target_crypto: target_crypto,
          wallet_address: wallet_address
        }.merge(options)

        post_with_auth("/private/order", payload)
      end

      def get_crypto_deposit_address(crypto_currency:)
        get_with_auth("/private/wallet/deposit/#{crypto_currency}")
      end

      def get_exchange_rates(base_currency: "BRL", target_currencies: nil)
        params = {
          base: base_currency,
          targets: target_currencies
        }.compact

        get_with_auth("/private/exchange/rates", params)
      end

      def create_exchange_swap(from_amount:, from_currency:, to_currency:, **options)
        payload = {
          from_amount: from_amount,
          from_currency: from_currency,
          to_currency: to_currency
        }.merge(options)

        post_with_auth("/private/exchange/swap", payload)
      end

      def get_account_info
        get_with_auth("/private/account")
      end

      def update_account_info(**params)
        put_with_auth("/private/account", params)
      end

      private

      def get_with_auth(path, params = {})
        nonce = generate_nonce
        signature = generate_signature(params.merge(nonce: nonce))
        
        headers = {
          "public" => public_key,
          "sign" => signature
        }

        get(path, params.merge(nonce: nonce), headers)
      end

      def post_with_auth(path, body = {})
        nonce = generate_nonce
        signature = generate_signature(body.merge(nonce: nonce))
        
        headers = {
          "public" => public_key,
          "sign" => signature
        }

        post(path, body.merge(nonce: nonce), headers)
      end

      def put_with_auth(path, body = {})
        nonce = generate_nonce
        signature = generate_signature(body.merge(nonce: nonce))
        
        headers = {
          "public" => public_key,
          "sign" => signature
        }

        put(path, body.merge(nonce: nonce), headers)
      end

      def delete_with_auth(path)
        nonce = generate_nonce
        signature = generate_signature(nonce: nonce)
        
        headers = {
          "public" => public_key,
          "sign" => signature
        }

        delete(path, headers)
      end

      def generate_signature(data)
        # Flatten nested parameters
        flat_data = flatten_params(data)
        
        # Build query string
        query_string = build_query_string(flat_data)
        
        # Generate HMAC signature
        OpenSSL::HMAC.hexdigest("sha512", secret_key, query_string)
      end

      def flatten_params(params, prefix = nil)
        flattened = {}
        
        params.each do |key, value|
          full_key = prefix ? "#{prefix}#{key}" : key.to_s
          
          if value.is_a?(Hash)
            flattened.merge!(flatten_params(value, "#{full_key}"))
          elsif value.is_a?(Array)
            value.each_with_index do |item, index|
              if item.is_a?(Hash)
                flattened.merge!(flatten_params(item, "#{full_key}[#{index}]"))
              else
                flattened["#{full_key}[#{index}]"] = item
              end
            end
          else
            flattened[full_key] = value
          end
        end
        
        flattened
      end

      def build_query_string(params)
        sorted_params = params.sort_by { |k, _| k.to_s }
        
        query_parts = sorted_params.map do |key, value|
          "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
        end
        
        query_parts.join("&")
      end

      def generate_nonce
        Time.now.to_i.to_s
      end
    end
  end
end