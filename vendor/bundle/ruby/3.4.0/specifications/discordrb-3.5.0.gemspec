# -*- encoding: utf-8 -*-
# stub: discordrb 3.5.0 ruby lib

Gem::Specification.new do |s|
  s.name = "discordrb".freeze
  s.version = "3.5.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/shardlab/discordrb/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["meew0".freeze, "swarley".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-07-05"
  s.description = "A Ruby implementation of the Discord (https://discord.com) API.".freeze
  s.email = ["".freeze]
  s.homepage = "https://github.com/shardlab/discordrb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7".freeze)
  s.rubygems_version = "3.3.3".freeze
  s.summary = "Discord API for Ruby".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<ffi>.freeze, [">= 1.9.24".freeze])
  s.add_runtime_dependency(%q<opus-ruby>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rest-client>.freeze, [">= 2.0.0".freeze])
  s.add_runtime_dependency(%q<websocket-client-simple>.freeze, [">= 0.3.0".freeze])
  s.add_runtime_dependency(%q<discordrb-webhooks>.freeze, ["~> 3.5.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.10".freeze, "< 3".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.5.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11.0".freeze])
  s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.5.1".freeze])
  s.add_development_dependency(%q<rspec-prof>.freeze, ["~> 0.0.7".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.36.0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, ["~> 0.6.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21.0".freeze])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.9".freeze])
end
