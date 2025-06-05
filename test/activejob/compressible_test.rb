# frozen_string_literal: true

require "test_helper"

module ActiveJob
  class CompressibleTest < Minitest::Test
    class DummyCompressibleJob < ActiveJob::Base
      include ActiveJob::Compressible
      queue_as :default

      attr_reader :arg

      def perform(arg)
        @arg = arg
      end
    end

    SMALL_PAYLOAD = { "foo" => "bar" }.freeze
    LARGE_PAYLOAD = { "data" => "x" * (ActiveJob::Compressible.configuration.compression_threshold + 1) }.freeze

    def test_does_not_compress_small_payloads
      job = DummyCompressibleJob.new(SMALL_PAYLOAD)
      serialized = job.serialize
      refute serialized["arguments"].first.is_a?(Hash) && serialized["arguments"].first["_compressed"],
             "Small payload should not be compressed"
    end

    def test_compresses_and_decompresses_large_payloads
      job = DummyCompressibleJob.new(LARGE_PAYLOAD)
      serialized = job.serialize
      assert serialized["arguments"].first["_compressed"], "Large payload should be compressed"
      refute_equal serialized["arguments"].first["data"], LARGE_PAYLOAD, "Data should be compressed"

      # Simulate deserialization
      deserialized_job = DummyCompressibleJob.deserialize(serialized)
      deserialized_job.perform_now
      assert_equal LARGE_PAYLOAD, deserialized_job.arg
    end

    def test_handles_old_uncompressed_payloads
      # Simulate an old job with a plain hash argument
      old_job_data = DummyCompressibleJob.new(SMALL_PAYLOAD).serialize
      deserialized_job = DummyCompressibleJob.deserialize(old_job_data)
      deserialized_job.perform_now
      assert_equal SMALL_PAYLOAD, deserialized_job.arg
    end

    def test_configuration
      with_compression_threshold(500_000) do
        assert_equal 500_000, ActiveJob::Compressible.configuration.compression_threshold
      end
    end

    def test_compression_algorithm_constraint
      assert_raises(ArgumentError, "Only :zlib compression algorithm is currently supported") do
        ActiveJob::Compressible.configure do |config|
          config.compression_algorithm = :gzip
        end
      end
    end

    def test_dynamic_configuration_threshold_changes # rubocop:disable Metrics/MethodLength
      test_payload = create_test_payload_below_default(100_000)
      original_threshold = ActiveJob::Compressible.configuration.compression_threshold

      # Test 1: With default config, payload should NOT be compressed
      job1 = DummyCompressibleJob.new(test_payload)
      serialized1 = job1.serialize
      refute_compressed(serialized1, "Payload should NOT be compressed with default threshold")

      # Test 2: Change config to 200k below default (making threshold smaller)
      new_threshold = original_threshold - 200_000
      with_compression_threshold(new_threshold) do
        # Same payload should now BE compressed because threshold is lower
        job2 = DummyCompressibleJob.new(test_payload)
        serialized2 = job2.serialize
        assert_compressed(serialized2, "Payload should BE compressed with lower threshold")

        # Test 3: Verify decompression still works correctly
        deserialized_job = DummyCompressibleJob.deserialize(serialized2)
        deserialized_job.perform_now
        assert_equal test_payload, deserialized_job.arg, "Payload should decompress correctly"
      end
    end

    private

    def create_test_payload_below_default(bytes_below)
      original_threshold = ActiveJob::Compressible.configuration.compression_threshold
      test_payload_size = original_threshold - bytes_below
      { "data" => "x" * test_payload_size }.freeze
    end

    def assert_compressed(serialized, message)
      assert serialized["arguments"].first["_compressed"], message
    end

    def refute_compressed(serialized, message)
      refute serialized["arguments"].first.is_a?(Hash) && serialized["arguments"].first["_compressed"], message
    end
  end
end
