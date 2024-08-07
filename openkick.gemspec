require_relative 'lib/openkick/version'

Gem::Specification.new do |spec|
  spec.name          = 'openkick'
  spec.version       = Openkick::VERSION
  spec.summary       = 'Intelligent search made easy with Rails and Elasticsearch or OpenSearch'
  spec.homepage      = 'https://github.com/brandit/openkick'
  spec.license       = 'MIT'

  spec.author        = 'Andrew Kane'
  spec.email         = 'andrew@ankane.org'

  spec.files         = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_path  = 'lib'

  spec.required_ruby_version = '>= 3.1'

  spec.add_dependency 'activemodel', '>= 6.1'
  spec.add_dependency 'hashie'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
