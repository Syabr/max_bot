# frozen_string_literal: true

require_relative 'lib/max/bot/version'

Gem::Specification.new do |s|
  s.name        = 'max_bot'
  s.version     = Max::Bot::VERSION
  s.summary     = 'Ruby client for the MAX messenger Bot API'
  s.description = 'Send messages, long-poll GET /updates, manage webhook subscriptions. See https://dev.max.ru/docs-api'
  s.authors     = ['Sergey Syabrenko']
  s.email       = 'darthpains@gmail.com'
  s.files = Dir.chdir(__dir__) do
    Dir['lib/**/*.rb'] + Dir['test/**/*.rb'] + Dir['examples/*.rb'] + %w[README.md CHANGELOG.md LICENSE.txt Rakefile]
  end
  s.homepage    = 'https://dev.max.ru/docs-api'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.5.0'

  s.require_paths = ['lib']

  s.add_dependency 'faraday', '>= 1.0', '< 3.0'

  s.add_development_dependency 'minitest', '>= 5.0', '< 7'
  s.add_development_dependency 'rake', '>= 13.0', '< 15'
end
