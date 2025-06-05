# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "activejob-compressible"

require "minitest/autorun"
require "active_job"

ActiveJob::Base.queue_adapter = :test

# Reduce ActiveJob logging noise during tests
ActiveJob::Base.logger = Logger.new(File::NULL) if defined?(Logger)

class DummyCompressibleJob < ActiveJob::Base
  include ActiveJob::Compressible
  queue_as :default

  attr_reader :args, :kwargs

  def perform(*args, **kwargs)
    @args = args
    @kwargs = kwargs
  end
end

module CompressibleTestHelper
  def with_compression_threshold(new_threshold)
    original_threshold = ActiveJob::Compressible.configuration.compression_threshold

    ActiveJob::Compressible.configure do |config|
      config.compression_threshold = new_threshold
    end

    yield
  ensure
    ActiveJob::Compressible.configuration.compression_threshold = original_threshold
  end
end

# Include the helper in all test classes
module Minitest
  class Test
    include CompressibleTestHelper
  end
end
