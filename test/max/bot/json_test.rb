# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class JsonTest < Minitest::Test
      FakeResponse = Struct.new(:status, :body) do
        def success?
          status >= 200 && status < 300
        end
      end

      def test_deep_symbolize_nested
        input = { 'a' => 1, 'b' => [{ 'c' => 'd' }] }
        out = Json.deep_symbolize(input)

        assert_equal({ a: 1, b: [{ c: 'd' }] }, out)
      end

      def test_decode_response_success
        r = FakeResponse.new(200, '{"a":1}')
        assert_equal({ a: 1 }, Json.decode_response(r))
      end

      def test_decode_response_empty_body
        r = FakeResponse.new(200, '')
        assert_equal({}, Json.decode_response(r))
      end

      def test_decode_response_error_raises_api_error
        r = FakeResponse.new(422, '{"message":"nope"}')
        err = assert_raises(ApiError) { Json.decode_response(r) }
        assert_equal 422, err.status
        assert_equal 'nope', err.body[:message]
      end

      def test_decode_response_invalid_json
        r = FakeResponse.new(200, '{')
        assert_raises(ApiError) { Json.decode_response(r) }
      end
    end
  end
end
