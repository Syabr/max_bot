#!/usr/bin/env ruby
# frozen_string_literal: true

# Run from the repository root:
#   bundle install
#   export MAX_BOT_TOKEN="your_token"
#   bundle exec ruby examples/polling_bot.rb

require 'bundler/setup'
require 'logger'
require 'max_bot'

token = ENV['MAX_BOT_TOKEN']
abort 'Set MAX_BOT_TOKEN from the MAX platform (Chat bots → Integration → token).' if token.to_s.strip.empty?

logger = Logger.new($stdout)
logger.level = Logger::INFO

Max::Bot.configure do |c|
  c.connection_timeout = 95
  c.connection_open_timeout = 20
end

api = Max::Bot::Api.new(token)

Max::Bot::Client.new(
  token,
  timeout: 30,
  limit: 100,
  types: %w[message_created],
  logger: logger,
  error_backoff: 5
).run do |update|
  logger.debug(update.inspect)
  next unless Max::Bot::UpdateHelpers.message_created?(update)

  message = Max::Bot::UpdateHelpers.message_from(update)
  text = Max::Bot::UpdateHelpers.message_text(message)
  dest = Max::Bot::UpdateHelpers.message_destination(message)
  next if text.to_s.empty? || dest.nil?

  kind, id = dest
  api.send_message("Echo: #{text}", kind => id)
rescue Max::Bot::ApiError => e
  logger.error("API error #{e.status}: #{e}")
end
