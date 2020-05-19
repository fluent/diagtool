require_relative 'lib/fluent/diagtool/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-diagtool"
  spec.version       = Fluent::Diagtool::VERSION
  spec.authors       = ["kubotat"]
  spec.email         = ["tkubota@ctc-america.com"]

  spec.summary       = %q{Diagnostic Tool for Fluentd}
  spec.description   = %q{Bringing productivity of trouble shooting to the next level  by automating collection of Fluentd configurations, settings and OS parameters as well as masking sensitive information in logs and configurations.}
  spec.homepage      = "https://github.com/fluent/diagtool/tree/dev"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|tool|sample)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("fileutils", ["~> 1.0"])
  spec.add_runtime_dependency("json", ["~> 2.1"])
end
