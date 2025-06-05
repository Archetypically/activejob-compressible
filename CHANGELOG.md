# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-06-05

### Added

- Now properly handles all arguments and keyword arguments for compression.

## [1.0.0] - 2025-06-05

### Added
- Initial release of ActiveJob::Compressible gem
- Transparent compression/decompression for large ActiveJob payloads
- Automatic detection of Rails cache backend limits for smart defaults
- Configurable compression threshold via `ActiveJob::Compressible.configure`
- Support for zlib compression algorithm with base64 encoding
- Backward compatibility for existing uncompressed jobs
- Safe compression markers (`"_compressed"` key) for reliable detection
- Comprehensive test suite with dynamic configuration testing
- Support for Ruby >= 3.1 and Rails 6.0-8.x
- Detailed documentation and usage examples

### Technical Details
- Uses zlib compression with base64 encoding for safety
- Only compresses Hash arguments that exceed the configured threshold
- Defaults to cache `value_max_bytes` minus 100KB for safety margin
- Graceful fallback to 948KB default if cache limits not detected
- Thread-safe configuration system
- Minimal performance overhead (~1-5ms for typical payloads)

### Documentation
- Complete README with usage examples and configuration options
- API documentation with inline comments
- Development setup and testing instructions
- Performance characteristics and compatibility notes
