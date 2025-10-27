# frozen_string_literal: true

require "faraday"
require "json"

module UnifiedPaymentGateway
  class BaseClient
    attr_reader :base_url, :logger, :timeout, :retry_attempts

    def initialize(base_url:, timeout: 30, retry_attempts: 3, logger: nil)
      @base_url = base_url
      @timeout = timeout
      @retry_attempts = retry_attempts
      @logger = logger || UnifiedPaymentGateway::Logger.default_logger
    end

    def get(path, params = {}, headers = {})
      request(:get, path, params, headers)
    end

    def post(path, body = {}, headers = {})
      request(:post, path, body, headers)
    end

    def put(path, body = {}, headers = {})
      request(:put, path, body, headers)
    end

    def delete(path, headers = {})
      request(:delete, path, nil, headers)
    end

    private

    def request(method, path, data = nil, headers = {})
      url = URI.join(base_url, path).to_s
      
      logger.debug "#{method.upcase} #{url}"
      
      response = with_retry do
        connection.send(method) do |req|
          req.url url
          req.headers.merge!(default_headers.merge(headers))
          req.options.timeout = timeout
          
          case method
          when :get, :delete
            req.params = data if data
          when :post, :put
            req.body = data.to_json if data
          end
        end
      end

      handle_response(response)
    rescue Faraday::TimeoutError => e
      logger.error "Request timeout: #{e.message}"
      raise NetworkError, "Request timeout: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      logger.error "Connection failed: #{e.message}"
      raise NetworkError, "Connection failed: #{e.message}"
    rescue JSON::ParserError => e
      logger.error "JSON parse error: #{e.message}"
      raise APIError, "Invalid JSON response: #{e.message}"
    end

    def connection
      @connection ||= Faraday.new do |faraday|
        faraday.request :json
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end

    def default_headers
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "User-Agent" => "UnifiedPaymentGateway/#{UnifiedPaymentGateway::VERSION}"
      }
    end

    def with_retry
      attempts = 0
      begin
        yield
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        attempts += 1
        if attempts < retry_attempts
          logger.warn "Retrying request (#{attempts}/#{retry_attempts}): #{e.message}"
          sleep(2 ** attempts)
          retry
        else
          raise e
        end
      end
    end

    def handle_response(response)
      logger.debug "Response status: #{response.status}"
      logger.debug "Response body: #{response.body}"

      case response.status
      when 200..299
        response.body
      when 400
        raise ValidationError, parse_error_message(response.body)
      when 401
        raise AuthenticationError, "Invalid credentials"
      when 403
        raise AuthenticationError, "Access forbidden"
      when 404
        raise PaymentNotFoundError, "Resource not found"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 500..599
        raise APIError, "Server error: #{response.status}"
      else
        raise APIError, "Unexpected response: #{response.status}"
      end
    end

    def parse_error_message(body)
      return "Unknown error" unless body
      
      if body.is_a?(Hash)
        body["error"] || body["message"] || "Unknown error"
      else
        "Unknown error"
      end
    end
  end
end