# -*- encoding: utf-8 -*-
# stub: opus-ruby 1.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "opus-ruby".freeze
  s.version = "1.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Matthew Perry".freeze]
  s.date = "2014-07-13"
  s.description = "Ruby FFI Gem for the OPUS Audio Codec".freeze
  s.email = ["muffinman616@gmail.com".freeze]
  s.homepage = "".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.2.2".freeze
  s.summary = "Ruby FFI wrapper for the OPUS Audio Codec C library for audio encoding".freeze

  s.installed_by_version = "3.6.9".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<ffi>.freeze, [">= 0".freeze])
end
