# frozen_string_literal: true

require "logger"

module UnifiedPaymentGateway
  class Logger
    def self.setup_logger(level = ::Logger::INFO)
      logger = ::Logger.new($stdout)
      logger.level = level
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end
      logger
    end

    def self.default_logger
      @default_logger ||= setup_logger
    end
  end
end