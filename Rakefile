# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run tests with coverage"
task :coverage do
  ENV["COVERAGE"] = "true"
  Rake::Task["spec"].invoke
end

desc "Run RuboCop"
task :rubocop do
  sh "rubocop"
end

desc "Run all quality checks"
task quality: %i[rubocop spec]