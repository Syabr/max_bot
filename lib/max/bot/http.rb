# frozen_string_literal: true

module Max
  module Bot
    # Low-level HTTP client (Faraday). Use {Api} for public endpoints.
    class Http
      attr_reader :token, :base_url

      def initialize(token, base_url, connection: nil)
        @token = token.to_s
        @base_url = base_url.to_s.chomp('/')
        @injected_connection = connection
      end

      def get(path, query: {})
        perform(:get, path, query: query)
      end

      def post(path, query: nil, body: nil)
        perform(:post, path, query: query, body: body)
      end

      def delete(path, query: nil)
        perform(:delete, path, query: query)
      end

      def put(path, query: nil, body: nil)
        perform(:put, path, query: query, body: body)
      end

      private

      def perform(method, path, query: nil, body: nil)
        resp = connection.run_request(method, path, nil, nil) do |req|
          req.headers['Authorization'] = token
          if body
            req.headers['Content-Type'] = 'application/json; charset=utf-8'
            req.body = ::JSON.generate(body)
          end
          req.params.update(query) if query&.any?
        end
        Json.decode_response(resp)
      end

      def connection
        @injected_connection || @default_connection ||= build_connection
      end

      def build_connection
        Faraday.new(url: base_url) do |f|
          f.adapter Bot.configuration.adapter
          f.options.timeout = Bot.configuration.connection_timeout
          f.options.open_timeout = Bot.configuration.connection_open_timeout
        end
      end
    end
  end
end
