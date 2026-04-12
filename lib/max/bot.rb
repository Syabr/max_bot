# frozen_string_literal: true

require 'json'
require 'faraday'

require_relative 'bot/version'
require_relative 'bot/configuration'
require_relative 'bot/errors'
require_relative 'bot/json'
require_relative 'bot/http'
require_relative 'bot/attachments'
require_relative 'bot/multipart_upload'
require_relative 'bot/api/request_builders'
require_relative 'bot/api'
require_relative 'bot/client'
require_relative 'bot/webhook'
require_relative 'bot/update_helpers'

module Max
  module Bot
    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end
    end
  end
end
