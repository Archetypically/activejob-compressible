# frozen_string_literal: true

require "test_helper"

class IntegrationTest < ActiveJob::TestCase
  LARGE_STRING = "x" * (ActiveJob::Compressible.configuration.compression_threshold + 1)
  LARGE_PAYLOAD = {
    "webhook_data" => LARGE_STRING,
    "metadata" => { "id" => 12_345, "type" => "test" }
  }.freeze

  def test_end_to_end_compression_and_decompression # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Step 1: Enqueue job with large payload
    job = DummyCompressibleJob.perform_later(LARGE_PAYLOAD, kwarg: LARGE_STRING)

    # Step 2: Verify job was enqueued
    assert_equal 1, enqueued_jobs.size, "Job should be enqueued"

    # Step 3: Verify compression occurred during serialization
    job_data = enqueued_jobs.first
    compressed_args = job_data["arguments"]
    assert compressed_args.is_a?(Hash), "Arguments should be a hash"
    assert compressed_args["_compressed"], "Large payload should be compressed"
    assert compressed_args["data"], "Compressed data should be present"
    refute_equal compressed_args["data"], [LARGE_PAYLOAD], "Data should be compressed"

    # Step 5: Process the enqueued job (triggers deserialization/decompression)
    job.perform_now

    # Step 6: Verify job executed successfully with correct payload
    assert_equal LARGE_PAYLOAD, job.args.first, "Job should receive original uncompressed payload"
    assert_equal LARGE_STRING, job.kwargs[:kwarg], "Job should receive original uncompressed payload"
  end
end
