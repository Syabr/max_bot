# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class ErrorsTest < Minitest::Test
      def test_api_error_to_s_includes_message_field
        err = ApiError.new('HTTP 400', status: 400, body: { message: 'bad request' })
        assert_match(/HTTP 400/, err.to_s)
        assert_match(/bad request/, err.to_s)
      end

      def test_api_error_attributes
        err = ApiError.new('x', status: 404, body: { code: 1 })
        assert_equal 404, err.status
        assert_equal({ code: 1 }, err.body)
      end
    end
  end
end
