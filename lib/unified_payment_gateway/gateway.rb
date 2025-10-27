# frozen_string_literal: true

module UnifiedPaymentGateway
  class Gateway
    attr_reader :kamoney_client, :nowpayments_client, :logger

    def initialize
      config = UnifiedPaymentGateway.configuration
      config.validate!

      @logger = config.logger || UnifiedPaymentGateway::Logger.default_logger
      
      @kamoney_client = Kamoney::Client.new(
        public_key: config.kamoney_public_key,
        secret_key: config.kamoney_secret_key,
        base_url: config.kamoney_base_url,
        timeout: config.timeout,
        retry_attempts: config.retry_attempts,
        logger: logger
      )

      @nowpayments_client = Nowpayments::Client.new(
        api_key: config.nowpayments_api_key,
        base_url: config.nowpayments_base_url,
        timeout: config.timeout,
        retry_attempts: config.retry_attempts,
        logger: logger
      )
    end

    # Unified Payment Methods

    def create_payment(provider:, amount:, currency:, **options)
      case provider.to_s.downcase
      when "kamoney", "kamoney_pix"
        create_kamoney_payment(amount: amount, currency: currency, **options)
      when "nowpayments", "crypto"
        create_nowpayments_payment(amount: amount, currency: currency, **options)
      else
        raise ValidationError, "Unsupported payment provider: #{provider}"
      end
    end

    def get_payment_status(provider:, payment_id:)
      case provider.to_s.downcase
      when "kamoney", "kamoney_pix"
        get_kamoney_payment_status(payment_id: payment_id)
      when "nowpayments", "crypto"
        get_nowpayments_payment_status(payment_id: payment_id)
      else
        raise ValidationError, "Unsupported payment provider: #{provider}"
      end
    end

    def create_payout(provider:, amount:, currency:, **options)
      case provider.to_s.downcase
      when "kamoney", "kamoney_pix"
        create_kamoney_payout(amount: amount, currency: currency, **options)
      when "nowpayments", "crypto"
        create_nowpayments_payout(amount: amount, currency: currency, **options)
      else
        raise ValidationError, "Unsupported payout provider: #{provider}"
      end
    end

    def get_balance(provider:, currency: nil)
      case provider.to_s.downcase
      when "kamoney", "kamoney_pix"
        get_kamoney_balance
      when "nowpayments", "crypto"
        get_nowpayments_balance(currency: currency)
      else
        raise ValidationError, "Unsupported provider: #{provider}"
      end
    end

    # KAMONEY-specific methods

    def create_kamoney_payment(amount:, currency:, **options)
      service = options.delete(:service) || determine_kamoney_service(currency)
      
      response = kamoney_client.create_order(
        amount: amount,
        service: service,
        **options
      )

      parse_kamoney_response(response, :payment)
    end

    def create_kamoney_pix_payment(amount:, pix_key:, **options)
      response = kamoney_client.create_pix_payment(
        amount: amount,
        pix_key: pix_key,
        **options
      )

      parse_kamoney_response(response, :payment)
    end

    def send_kamoney_pix_payment(amount:, pix_key:, **options)
      response = kamoney_client.send_pix_payment(
        amount: amount,
        pix_key: pix_key,
        **options
      )

      parse_kamoney_response(response, :pix_transfer)
    end

    def create_kamoney_bank_transfer(amount:, bank_code:, agency:, account:, account_type:, **options)
      response = kamoney_client.create_bank_transfer(
        amount: amount,
        bank_code: bank_code,
        agency: agency,
        account: account,
        account_type: account_type,
        **options
      )

      parse_kamoney_response(response, :payment)
    end

    def get_kamoney_payment_status(payment_id:)
      response = kamoney_client.get_order(id: payment_id)
      parse_kamoney_response(response, :payment_status)
    end

    def create_kamoney_payout(amount:, currency:, **options)
      service = options.delete(:service) || determine_kamoney_service(currency)
      
      response = kamoney_client.create_withdrawal(
        amount: amount,
        service: service,
        **options
      )

      parse_kamoney_response(response, :payout)
    end

    def get_kamoney_balance
      response = kamoney_client.get_wallet_balance
      parse_kamoney_response(response, :balance)
    end

    def get_kamoney_services
      {
        order: kamoney_client.get_services_order,
        merchant: kamoney_client.get_services_merchant,
        buy: kamoney_client.get_services_buy
      }
    end

    def get_kamoney_withdrawals_list(page: 1, limit: 50, status: nil, start_date: nil, end_date: nil)
      response = kamoney_client.get_withdrawals_list(
        page: page,
        limit: limit,
        status: status,
        start_date: start_date,
        end_date: end_date
      )
      parse_kamoney_response(response, :withdrawals_list)
    end

    def create_kamoney_crypto_withdrawal(amount:, crypto_currency:, wallet_address:, **options)
      response = kamoney_client.create_crypto_withdrawal(
        amount: amount,
        crypto_currency: crypto_currency,
        wallet_address: wallet_address,
        **options
      )
      parse_kamoney_response(response, :crypto_withdrawal)
    end

    def create_kamoney_pix_to_crypto_conversion(amount:, pix_key:, target_crypto:, wallet_address:, **options)
      response = kamoney_client.create_pix_to_crypto_conversion(
        amount: amount,
        pix_key: pix_key,
        target_crypto: target_crypto,
        wallet_address: wallet_address,
        **options
      )
      parse_kamoney_response(response, :pix_crypto_conversion)
    end

    def get_kamoney_crypto_deposit_address(crypto_currency:)
      response = kamoney_client.get_crypto_deposit_address(crypto_currency: crypto_currency)
      parse_kamoney_response(response, :crypto_deposit_address)
    end

    def get_kamoney_exchange_rates(base_currency: "BRL", target_currencies: nil)
      response = kamoney_client.get_exchange_rates(
        base_currency: base_currency,
        target_currencies: target_currencies
      )
      parse_kamoney_response(response, :exchange_rates)
    end

    def create_kamoney_exchange_swap(from_amount:, from_currency:, to_currency:, **options)
      response = kamoney_client.create_exchange_swap(
        from_amount: from_amount,
        from_currency: from_currency,
        to_currency: to_currency,
        **options
      )
      parse_kamoney_response(response, :exchange_swap)
    end

    # NOWPAYMENTS-specific methods

    def create_nowpayments_payment(amount:, currency:, **options)
      pay_currency = options.delete(:pay_currency) || currency
      
      response = nowpayments_client.create_payment(
        price_amount: amount,
        price_currency: currency,
        pay_currency: pay_currency,
        **options
      )

      parse_nowpayments_response(response, :payment)
    end

    def create_nowpayments_invoice(amount:, currency:, **options)
      response = nowpayments_client.create_invoice(
        price_amount: amount,
        price_currency: currency,
        **options
      )

      parse_nowpayments_response(response, :invoice)
    end

    def get_nowpayments_payment_status(payment_id:)
      response = nowpayments_client.get_payment_status(payment_id: payment_id)
      parse_nowpayments_response(response, :payment_status)
    end

    def create_nowpayments_payout(amount:, currency:, **options)
      withdrawals = options.delete(:withdrawals) || [{
        address: options.delete(:address),
        amount: amount,
        currency: currency
      }]

      response = nowpayments_client.create_payout(
        withdrawals: withdrawals,
        **options
      )

      parse_nowpayments_response(response, :payout)
    end

    def get_nowpayments_balance(currency: nil)
      response = nowpayments_client.get_balance
      parse_nowpayments_response(response, :balance, currency: currency)
    end

    def get_nowpayments_currencies(fixed_rate: false, fiat: false)
      response = nowpayments_client.get_available_currencies(
        fixed_rate: fixed_rate,
        fiat: fiat
      )
      parse_nowpayments_response(response, :currencies)
    end

    def get_nowpayments_estimated_price(amount:, currency_from:, currency_to:)
      response = nowpayments_client.get_estimated_price(
        amount: amount,
        currency_from: currency_from,
        currency_to: currency_to
      )
      parse_nowpayments_response(response, :price_estimate)
    end

    def create_nowpayments_mass_payout(withdrawals:, ipn_callback_url: nil)
      response = nowpayments_client.create_mass_payout(
        withdrawals: withdrawals,
        ipn_callback_url: ipn_callback_url
      )
      parse_nowpayments_response(response, :mass_payout)
    end

    def get_nowpayments_mass_payout_status(batch_id:)
      response = nowpayments_client.get_mass_payout_status(batch_id: batch_id)
      parse_nowpayments_response(response, :mass_payout_status)
    end

    def get_nowpayments_mass_payouts_list(page: 1, limit: 50, date_from: nil, date_to: nil)
      response = nowpayments_client.get_mass_payouts_list(
        page: page,
        limit: limit,
        date_from: date_from,
        date_to: date_to
      )
      parse_nowpayments_response(response, :mass_payouts_list)
    end

    def get_nowpayments_payout_limits(currency:)
      response = nowpayments_client.get_payout_limits(currency: currency)
      parse_nowpayments_response(response, :payout_limits)
    end

    def validate_nowpayments_payout_address(address:, currency:)
      response = nowpayments_client.validate_payout_address(
        address: address,
        currency: currency
      )
      parse_nowpayments_response(response, :address_validation)
    end

    def get_nowpayments_available_payout_currencies()
      response = nowpayments_client.get_available_payout_currencies()
      parse_nowpayments_response(response, :available_payout_currencies)
    end

    def get_nowpayments_minimum_amount(currency_from:, currency_to:)
      response = nowpayments_client.get_minimum_payment_amount(
        currency_from: currency_from,
        currency_to: currency_to
      )
      parse_nowpayments_response(response, :minimum_amount)
    end

    private

    def determine_kamoney_service(currency)
      case currency.to_s.upcase
      when "BRL", "PIX"
        "pix"
      when "BOLETO"
        "payment_slips"
      when "TRANSFER", "TED", "DOC"
        "direct_transfers"
      else
        "pix" # Default to PIX
      end
    end

    def parse_kamoney_response(response, type)
      return response unless response["success"] == true

      case type
      when :payment
        {
          provider: "kamoney",
          payment_id: response["data"]["id"],
          status: response["data"]["status"],
          amount: response["data"]["amount"],
          currency: "BRL",
          qr_code: response["data"]["qr_code"],
          pix_key: response["data"]["pix_key"],
          expires_at: response["data"]["expires_at"],
          raw_response: response
        }
      when :payment_status
        {
          provider: "kamoney",
          payment_id: response["data"]["id"],
          status: response["data"]["status"],
          amount: response["data"]["amount"],
          currency: "BRL",
          created_at: response["data"]["created_at"],
          updated_at: response["data"]["updated_at"],
          raw_response: response
        }
      when :balance
        {
          provider: "kamoney",
          balances: response["data"],
          raw_response: response
        }
      when :payout
        {
          provider: "kamoney",
          payout_id: response["data"]["id"],
          status: response["data"]["status"],
          amount: response["data"]["amount"],
          currency: "BRL",
          raw_response: response
        }
      when :pix_transfer
        {
          provider: "kamoney",
          transfer_id: response["data"]["id"],
          status: response["data"]["status"],
          amount: response["data"]["amount"],
          currency: "BRL",
          pix_key: response["data"]["pix_key"],
          created_at: response["data"]["created_at"],
          raw_response: response
        }
      else
        response
      end
    end

    def parse_nowpayments_response(response, type, currency: nil)
      case type
      when :payment
        {
          provider: "nowpayments",
          payment_id: response["payment_id"],
          payment_url: response["payment_url"],
          pay_address: response["pay_address"],
          price_amount: response["price_amount"],
          price_currency: response["price_currency"],
          pay_amount: response["pay_amount"],
          pay_currency: response["pay_currency"],
          order_id: response["order_id"],
          order_description: response["order_description"],
          status: response["payment_status"],
          created_at: response["created_at"],
          raw_response: response
        }
      when :invoice
        {
          provider: "nowpayments",
          invoice_id: response["id"],
          invoice_url: response["invoice_url"],
          price_amount: response["price_amount"],
          price_currency: response["price_currency"],
          status: response["status"],
          created_at: response["created_at"],
          raw_response: response
        }
      when :payment_status
        {
          provider: "nowpayments",
          payment_id: response["payment_id"],
          status: response["payment_status"],
          pay_address: response["pay_address"],
          price_amount: response["price_amount"],
          price_currency: response["price_currency"],
          pay_amount: response["pay_amount"],
          actually_paid: response["actually_paid"],
          pay_currency: response["pay_currency"],
          order_id: response["order_id"],
          created_at: response["created_at"],
          updated_at: response["updated_at"],
          raw_response: response
        }
      when :balance
        if currency
          balance = response[currency.to_s.downcase]
          {
            provider: "nowpayments",
            currency: currency.to_s.upcase,
            available: balance&.dig("amount"),
            pending: balance&.dig("pendingAmount"),
            raw_response: response
          }
        else
          {
            provider: "nowpayments",
            balances: response,
            raw_response: response
          }
        end
      when :payout
        {
          provider: "nowpayments",
          payout_id: response["id"],
          status: response["status"],
          withdrawals: response["withdrawals"],
          created_at: response["created_at"],
          raw_response: response
        }
      when :currencies
        {
          provider: "nowpayments",
          currencies: response["currencies"] || response,
          raw_response: response
        }
      when :price_estimate
        {
          provider: "nowpayments",
          estimated_amount: response["estimated_amount"],
          currency_from: response["currency_from"],
          currency_to: response["currency_to"],
          raw_response: response
        }
      when :minimum_amount
        {
          provider: "nowpayments",
          min_amount: response["min_amount"],
          currency_from: response["currency_from"],
          currency_to: response["currency_to"],
          raw_response: response
        }
      else
        response
      end
    end
  end
end