# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "batchmaker/version"

Gem::Specification.new do |spec|
  spec.name          = "batchmaker"
  spec.version       = Batchmaker::VERSION
  spec.authors       = ["Doximity"]
  spec.email         = ["engineering@doximity.com"]

  spec.summary       = "Async queue system that batches items together based on time and size"
  spec.description   = "Async queue system that batches items together based on time and size"
  spec.homepage      = "https://github.com/doximity/batchmaker"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(bin|test|spec|features|vendor|tasks|tmp)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "dox-style"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "sdoc"
end
