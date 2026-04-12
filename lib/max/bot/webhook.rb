# frozen_string_literal: true

module Max
  module Bot
    # Helpers for HTTPS webhook endpoints (POST body = Update JSON).
    # Optional header X-Max-Bot-Api-Secret when a subscription secret is set.
    # https://dev.max.ru/docs-api/methods/POST/subscriptions
    module Webhook
      SECRET_HEADER = 'X-Max-Bot-Api-Secret'

      module_function

      def secret_valid?(header_value, expected_secret)
        return true if expected_secret.nil? || expected_secret.to_s.empty?

        a = header_value.to_s
        b = expected_secret.to_s
        return false unless a.bytesize == b.bytesize

        l = 0
        a.bytes.zip(b.bytes) { |x, y| l |= x ^ y }
        l.zero?
      end

      def extract_secret_header(env)
        return unless env.is_a?(Hash)

        env['HTTP_X_MAX_BOT_API_SECRET'] || env[SECRET_HEADER]
      end

      def parse_json(body)
        return {} if body.nil? || body.to_s.empty?

        JSON.parse(body.to_s, symbolize_names: true)
      end
    end
  end
end
