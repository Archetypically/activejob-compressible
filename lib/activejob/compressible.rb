# frozen_string_literal: true

require "active_support/concern"
require "zlib"
require "base64"
require "json"

module ActiveJob
  # CompressibleJob is a concern for ActiveJob classes that transparently compresses
  # and decompresses large job arguments to avoid exceeding cache or queue backend limits
  # (such as Dalli/Memcached or Redis). This is especially useful for jobs that handle
  # large payloads, such as webhook events or API responses.
  #
  # Usage:
  #   class MyJob < ApplicationJob
  #     include ActiveJob::Compressible
  #     # ...
  #   end
  #
  # How it works:
  #   - When the job is serialized (enqueued), all arguments are checked together.
  #   - If the arguments' JSON representation exceeds the compression threshold,
  #     they are compressed using zlib and base64, and marked with a special key.
  #   - When the job is deserialized (dequeued), the arguments are checked for the marker and
  #     transparently decompressed if needed.
  #   - Old jobs (with uncompressed payloads) are still supported for backward compatibility.
  #
  # Configuration:
  #   - The compression threshold is configurable via ActiveJob::Compressible.configuration
  #   - Defaults to cache backend's :value_max_bytes minus 100,000 bytes for safety
  #
  # This concern is safe for rolling deployments and can be included in any job class that may
  # enqueue large payloads.
  module Compressible
    extend ActiveSupport::Concern

    included do
      def serialize
        super.tap do |h|
          h["arguments"] = self.class.compress_if_needed(h["arguments"]) if h["arguments"]
        end
      end
    end

    class_methods do
      def deserialize(job_data)
        job_data = job_data.dup
        job_data["arguments"] = decompress_if_needed(job_data["arguments"])
        super
      end

      def compress_if_needed(obj)
        json_str = obj.to_json
        if json_str.bytesize > compression_threshold
          compressed = Base64.encode64(Zlib::Deflate.deflate(json_str))
          { "_compressed" => true, "data" => compressed }
        else
          obj
        end
      end

      def decompress_if_needed(arg)
        if arg.is_a?(Hash) && arg["_compressed"]
          JSON.parse(Zlib::Inflate.inflate(Base64.decode64(arg["data"])))
        else
          arg
        end
      end

      def compression_threshold
        ActiveJob::Compressible.configuration.compression_threshold
      end
    end
  end
end
