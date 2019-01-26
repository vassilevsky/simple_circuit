# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simple_circuit"

Gem::Specification.new do |spec|
  spec.name          = "simple_circuit"
  spec.version       = SimpleCircuit::VERSION
  spec.authors       = ["Ilya Vassilevsky"]
  spec.email         = ["vassilevsky@gmail.com"]

  spec.summary       = "Allows a service to fail fast to prevent overload"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
