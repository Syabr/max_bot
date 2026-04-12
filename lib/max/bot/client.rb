# frozen_string_literal: true

module Max
  module Bot
    # Polls the MAX Bot API with GET /updates and yields each update to your block.
    class Client
      attr_reader :api, :options

      def self.run(token, **options, &block)
        raise ArgumentError, 'block required' unless block

        new(token, **options).run(&block)
      end

      def initialize(token, **options)
        @options = default_options.merge(options)
        url = @options.delete(:url) || Api::DEFAULT_URL
        @api = @options.delete(:api) || Api.new(token, url: url)
      end

      def run(&block)
        raise ArgumentError, 'block required' unless block

        marker = options[:marker]
        limit = options.fetch(:limit, 100)
        timeout = options.fetch(:timeout, 30)
        types = options[:types]
        backoff = options.fetch(:error_backoff, 3).to_f
        backoff = 0.5 if backoff < 0.5

        loop do
          result = fetch_updates(marker: marker, limit: limit, timeout: timeout, types: types)
          marker = advance_marker(result, marker)
          deliver_updates(result, &block)
        rescue Interrupt
          raise
        rescue ApiError, Faraday::Error => e
          handle_poll_error(e, backoff)
        end
      end

      private

      def fetch_updates(marker:, limit:, timeout:, types:)
        api.get_updates(marker: marker, limit: limit, timeout: timeout, types: types)
      end

      def advance_marker(result, marker)
        return marker unless result.is_a?(Hash) && result.key?(:marker)

        result[:marker]
      end

      def deliver_updates(result, &block)
        updates = result.is_a?(Hash) ? (result[:updates] || []) : []
        updates.each(&block)
      end

      def handle_poll_error(error, backoff)
        if (cb = options[:on_error])
          cb.call(error)
        elsif (log = options[:logger]) && log.respond_to?(:warn)
          log.warn("#{error.class}: #{error.message} — retrying in #{backoff}s")
        end
        sleeper = options[:sleep] || ->(duration) { Kernel.sleep(duration) }
        sleeper.call(backoff)
      end

      def default_options
        {
          limit: 100,
          timeout: 30,
          types: nil,
          marker: nil,
          error_backoff: 3,
          on_error: nil,
          logger: nil,
          sleep: nil
        }
      end
    end
  end
end
