# frozen_string_literal: true

module ActiveJob
  # Compressible module provides transparent compression for large ActiveJob payloads.
  module Compressible
    # Configuration class for ActiveJob::Compressible settings.
    #
    # Manages compression behavior including threshold limits and algorithm selection.
    # The compression threshold determines when job arguments should be compressed
    # based on their serialized size.
    class Configuration
      attr_accessor :compression_threshold
      attr_reader :compression_algorithm

      def initialize
        @compression_threshold = default_compression_threshold
        @compression_algorithm = :zlib
      end

      def compression_algorithm=(algorithm)
        raise ArgumentError, "Only :zlib compression algorithm is currently supported" unless algorithm == :zlib

        @compression_algorithm = algorithm
      end

      private

      def default_compression_threshold
        max_bytes = begin
          Rails.cache.options[:value_max_bytes] if defined?(Rails)
        rescue StandardError
          nil
        end || 1_048_576
        max_bytes - 100_000
      end
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end
  end
end
