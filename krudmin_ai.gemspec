$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "krudmin_ai/version"

Gem::Specification.new do |spec|
  spec.name = "krudmin_ai"
  spec.version = KrudminAI::VERSION
  spec.authors = ["KrudminAI contributors"]
  spec.summary = "A secure, Hotwire-first Rails engine for admin applications."
  spec.description = "KrudminAI provides policy-aware, tenant-aware foundations for Rails admin applications."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"
  spec.files = Dir.chdir(__dir__) { Dir["{app,config,lib,templates}/**/*", "LICENSE", "README.md"] }

  spec.add_dependency "erb", ">= 4.0", "< 6.0"
  spec.add_dependency "rails", ">= 8.1", "< 10.0"
  spec.add_dependency "propshaft", ">= 1.0"
  spec.add_dependency "stimulus-rails", ">= 1.3"
  spec.add_dependency "turbo-rails", ">= 2.0"
  spec.add_development_dependency "rubocop", ">= 1.0"
  spec.add_development_dependency "rspec-rails", ">= 7.0"
end