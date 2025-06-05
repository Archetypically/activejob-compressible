# ActiveJob::Compressible

Transparent compression for large ActiveJob payloads to avoid cache backend limits.

[![CI](https://github.com/Archetypically/activejob-compressible/actions/workflows/ci.yml/badge.svg)](https://github.com/Archetypically/activejob-compressible/actions/workflows/ci.yml)

## Overview

The `ActiveJob::Compressible` concern provides automatic compression and decompression for large job arguments to prevent exceeding cache or queue backend size limits (such as Redis/Memcached). This is especially useful for jobs that handle large payloads like webhook events, API responses, or bulk data processing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activejob-compressible'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install activejob-compressible

## Usage

Include the concern in your job classes:

```ruby
class WebhookJob < ApplicationJob
  include ActiveJob::Compressible

  def perform(large_webhook_payload)
    # Process the payload - compression/decompression is transparent
    process_webhook(large_webhook_payload)
  end
end
```

## How It Works

- **Automatic Compression**: When jobs are serialized (enqueued), the first argument is checked. If it's a Hash and its JSON representation exceeds the compression threshold, it's automatically compressed using zlib and base64 encoding.

- **Transparent Decompression**: When jobs are deserialized (dequeued), compressed arguments are automatically detected and decompressed.

- **Backward Compatibility**: Old jobs (created before adding the concern) continue to work without any changes during rolling deployments.

- **Safe Markers**: Compressed payloads are marked with a `"_compressed"` key to ensure reliable detection.

## Configuration

```ruby
ActiveJob::Compressible.configure do |config|
  config.compression_threshold = 500_000  # Compress payloads > 500KB
end
```

### Configuration Options

- **`compression_threshold`**: Size in bytes above which payloads will be compressed. Defaults to your cache backend's `value_max_bytes` minus 100KB for safety, or 948KB if not detected.

- **`compression_algorithm`**: Currently only `:zlib` is supported.

### Default Behavior

The gem automatically detects your Rails cache configuration and sets a safe default threshold:

```ruby
# Automatically uses your cache backend's limits
max_bytes = Rails.cache.options[:value_max_bytes] || 1_048_576
default_threshold = max_bytes - 100_000  # Safe margin
```

## Examples

### Basic Usage

```ruby
class DataProcessingJob < ApplicationJob
  include ActiveJob::Compressible

  def perform(large_dataset)
    # large_dataset is automatically compressed if > threshold
    process_data(large_dataset)
  end
end

# Enqueue with large payload
DataProcessingJob.perform_later({
  "records" => large_array_of_data,
  "metadata" => additional_info
})
```

### Custom Configuration

```ruby
# config/initializers/activejob_compressible.rb
ActiveJob::Compressible.configure do |config|
  config.compression_threshold = 750_000  # 750KB threshold
end
```

### Multiple Job Classes

```ruby
class ApiResponseJob < ApplicationJob
  include ActiveJob::Compressible
  # Inherits default configuration
end

class BulkImportJob < ApplicationJob
  include ActiveJob::Compressible
  # Also inherits default configuration
end
```

## Requirements

- Ruby >= 2.7.0
- ActiveJob >= 6.0
- ActiveSupport >= 6.0

## Compatibility

- **Rails 6.0-8.x**: Full support
- **Queue Adapters**: Works with any ActiveJob queue adapter (Sidekiq, Resque, etc.)
- **Cache Backends**: Automatically detects Redis, Memcached, and other cache limits
- **Rolling Deployments**: Safe to deploy incrementally

## Performance

- **Compression Ratio**: Typically 60-90% size reduction for JSON payloads
- **Speed**: zlib compression/decompression adds ~1-5ms for typical payloads
- **Memory**: Minimal overhead, only processes large payloads

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

```bash
# Run tests
bundle exec rake test

# Run tests quietly
bundle exec rake test TESTOPTS="--quiet"

# Run RuboCop
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Archetypically/activejob-compressible.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
