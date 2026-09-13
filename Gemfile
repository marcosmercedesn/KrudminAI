source "https://rubygems.org"

gemspec

rails_requirements = ENV.fetch("RAILS_VERSION", ">= 8.1, < 10.0").split(",").map(&:strip)
gem "rails", *rails_requirements
