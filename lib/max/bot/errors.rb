# frozen_string_literal: true

module Max
  module Bot
    class Error < StandardError; end

    class ApiError < Error
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        super(message)
        @status = status
        @body = body
      end

      def to_s
        return super if body.nil? || !body.is_a?(Hash)

        detail = body[:message] || body['message']
        detail ? "#{super}: #{detail}" : super
      end
    end
  end
end
