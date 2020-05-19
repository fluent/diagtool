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


  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|tool|sample|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

end
