# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tl_capture/version'

Gem::Specification.new do |spec|
  spec.name          = "tl_capture"
  spec.version       = TlCapture::VERSION
  spec.authors       = ["hero"]
  spec.email         = ["hero@asterisk-works.jp"]
  spec.summary       = %q{Disaster Information capture}
  spec.description   = %q{Disaster Information capture}
  spec.homepage      = ""
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "twitter"
  spec.add_dependency "tweetstream"
  spec.add_dependency "fluent-logger"
  spec.add_dependency 'thor'

  spec.add_development_dependency "timecop"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "yard-rspec", "~> 0.1"
  spec.add_development_dependency "simplecov", "~> 0.10.0"
  spec.add_development_dependency "webmock", "~> 1.22.6"
  spec.add_development_dependency "vcr", "~> 3.0.0"

end
