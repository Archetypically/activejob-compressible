# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Override rake release to be a no-op in CI
if ENV["CI"] || ENV["GITHUB_ACTIONS"]
  Rake::Task["release"].clear
  desc "Release (disabled in CI - use manual releases instead)"
  task :release do
    puts "⚠️  rake release is disabled in CI environments"
    puts "   Use manual releases via GitHub Actions workflow instead"
    exit 0
  end
end

desc "Validate RBS type signatures"
task :rbs do
  sh "bundle exec rbs validate"
end

desc "Check last commit follows conventional commits format"
task :commit_lint do
  last_commit = `git log -1 --pretty=%s`.strip

  # Basic conventional commit pattern
  pattern = /^(feat|fix|docs|style|refactor|test|chore|ci)(\(.+\))?: .+/

  unless last_commit.match?(pattern)
    puts "❌ Last commit doesn't follow conventional commits format:"
    puts "   \"#{last_commit}\""
    puts ""
    puts "Expected format: <type>[optional scope]: <description>"
    puts "Examples:"
    puts "   feat: add new compression feature"
    puts "   fix(config): handle edge case in threshold calculation"
    puts "   docs: update README with usage examples"
    exit 1
  end

  puts "✅ Last commit follows conventional commits format"
end

task :up do
  sh "bundle install"
end

task default: %i[test rubocop rbs]
