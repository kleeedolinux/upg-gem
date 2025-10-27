# frozen_string_literal: true

require_relative "lib/unified_payment_gateway/version"

Gem::Specification.new do |spec|
  spec.name = "unified_payment_gateway"
  spec.version = UnifiedPaymentGateway::VERSION
  spec.authors = ["KleeedoLinux"]
  spec.email = ["kleeedolinux@gmail.com"]

  spec.summary = "A unified payment gateway interface for KAMONEY and NOWPAYMENTS"
  spec.description = "A Ruby gem that provides a unified interface for integrating with KAMONEY (PIX payments) and NOWPAYMENTS (cryptocurrency payments) APIs"
  spec.homepage = "https://github.com/kleeedolinux/upg-gem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kleeedolinux/upg-gem"
  spec.metadata["changelog_uri"] = "https://github.com/kleeedolinux/upg-gem/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-multipart", "~> 1.0"
  spec.add_dependency "json", "~> 2.0"
  spec.add_dependency "logger", "~> 1.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "simplecov", "~> 0.21"
  spec.add_development_dependency "yard", "~> 0.9"
end