# frozen_string_literal: true

require_relative "lib/activejob/compressible/version"

Gem::Specification.new do |spec|
  spec.name = "activejob-compressible"
  spec.version = ActiveJob::Compressible::VERSION
  spec.authors = ["Evan Lee"]
  spec.email = ["evan.lee@shopify.com"]

  spec.summary = "Transparent compression for large ActiveJob payloads"
  spec.description = "Automatically compress/decompress large job arguments to avoid size restrictions"
  spec.homepage = "https://github.com/Archetypically/activejob-compressible"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "CHANGELOG.md",
    "LICENSE",
    "README.md"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "activejob", ">= 6.0", "< 9.0"
  spec.add_dependency "activesupport", ">= 6.0", "< 9.0"
end
