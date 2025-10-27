# frozen_string_literal: true

module UnifiedPaymentGateway
  module Nowpayments
    class Client < BaseClient
      attr_reader :api_key

      def initialize(api_key:, base_url: nil, **options)
        super(base_url: base_url || UnifiedPaymentGateway.configuration.nowpayments_base_url, **options)
        @api_key = api_key
      end

      # Authentication
      def authenticate(email:, password:)
        post("/auth", {
          email: email,
          password: password
        })
      end

      # API Status
      def get_status
        get("/status")
      end

      # Balance
      def get_balance
        get("/balance", {}, auth_headers)
      end

      # Currencies
      def get_available_currencies(fixed_rate: false, fiat: false)
        params = {
          fixed_rate: fixed_rate,
          fiat: fiat
        }.compact

        get("/currencies", params, auth_headers)
      end

      def get_full_currencies_list
        get("/full-currencies", {}, auth_headers)
      end

      # Payment Operations
      def get_minimum_payment_amount(currency_from:, currency_to:, fiat: nil)
        params = {
          currency_from: currency_from,
          currency_to: currency_to,
          fiat: fiat
        }.compact

        get("/min-amount", params, auth_headers)
      end

      def get_estimated_price(amount:, currency_from:, currency_to:)
        params = {
          amount: amount,
          currency_from: currency_from,
          currency_to: currency_to
        }

        get("/estimate", params, auth_headers)
      end

      def create_payment(price_amount:, price_currency:, pay_currency:, **options)
        payload = {
          price_amount: price_amount,
          price_currency: price_currency,
          pay_currency: pay_currency
        }.merge(options)

        post("/payment", payload, auth_headers)
      end

      def create_invoice(price_amount:, price_currency:, **options)
        payload = {
          price_amount: price_amount,
          price_currency: price_currency
        }.merge(options)

        post("/invoice", payload, auth_headers)
      end

      def get_payment_status(payment_id:)
        get("/payment/#{payment_id}", {}, auth_headers)
      end

      def get_payment_status_by_order_id(order_id:)
        get("/payment", { order_id: order_id }, auth_headers)
      end

      def get_payments_list(page: 1, limit: 50, date_from: nil, date_to: nil)
        params = {
          page: page,
          limit: limit,
          date_from: date_from,
          date_to: date_to
        }.compact

        get("/payment/merchant/all", params, auth_headers)
      end

      # Payouts
      def create_payout(withdrawals:, ipn_callback_url: nil)
        payload = {
          withdrawals: withdrawals,
          ipn_callback_url: ipn_callback_url
        }.compact

        post("/payout", payload, auth_headers)
      end

      def verify_payout(withdrawal_id:, verification_code:)
        post("/payout/#{withdrawal_id}/verify", {
          verification_code: verification_code
        }, auth_headers)
      end

      def get_payout_status(payout_id:)
        get("/payout/#{payout_id}", {}, auth_headers)
      end

      def get_payouts_list(page: 1, limit: 50, date_from: nil, date_to: nil)
        params = {
          page: page,
          limit: limit,
          date_from: date_from,
          date_to: date_to
        }.compact

        get("/payout/merchant/all", params, auth_headers)
      end

      def create_mass_payout(withdrawals:, ipn_callback_url: nil)
        payload = {
          withdrawals: withdrawals,
          ipn_callback_url: ipn_callback_url
        }.compact

        post("/mass-payout", payload, auth_headers)
      end

      def get_mass_payout_status(batch_id:)
        get("/mass-payout/#{batch_id}", {}, auth_headers)
      end

      def get_mass_payouts_list(page: 1, limit: 50, date_from: nil, date_to: nil)
        params = {
          page: page,
          limit: limit,
          date_from: date_from,
          date_to: date_to
        }.compact

        get("/mass-payout/merchant/all", params, auth_headers)
      end

      def get_payout_limits(currency:)
        get("/payout/limits/#{currency}", {}, auth_headers)
      end

      def validate_payout_address(address:, currency:)
        post("/payout/validate", {
          address: address,
          currency: currency
        }, auth_headers)
      end

      def get_available_payout_currencies()
        get("/payout/currencies", {}, auth_headers)
      end

      # Recurring Payments
      def create_recurring_payment(email:, price_amount:, price_currency:, pay_currency:, **options)
        payload = {
          email: email,
          price_amount: price_amount,
          price_currency: price_currency,
          pay_currency: pay_currency
        }.merge(options)

        post("/recurring", payload, auth_headers)
      end

      def get_recurring_payment_status(recurring_id:)
        get("/recurring/#{recurring_id}", {}, auth_headers)
      end

      def cancel_recurring_payment(recurring_id:)
        delete("/recurring/#{recurring_id}", auth_headers)
      end

      # Billing (Sub-partner API)
      def create_sub_partner(email:, password:, **options)
        payload = {
          email: email,
          password: password
        }.merge(options)

        post("/sub-partner", payload, auth_headers)
      end

      def get_sub_partner_balance(partner_id:)
        get("/sub-partner/balance/#{partner_id}", {}, auth_headers)
      end

      def transfer_to_sub_partner(partner_id:, amount:, currency:)
        post("/sub-partner/transfer", {
          partner_id: partner_id,
          amount: amount,
          currency: currency
        }, auth_headers)
      end

      private

      def auth_headers
        {
          "x-api-key" => api_key
        }
      end
    end
  end
end