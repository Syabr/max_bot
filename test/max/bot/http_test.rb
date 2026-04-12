# frozen_string_literal: true

require 'test_helper'
require 'faraday'

module Max
  module Bot
    class HttpTest < Minitest::Test
      def test_get_parses_json
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get('/updates') { [200, { 'Content-Type' => 'application/json' }, '{"updates":[],"marker":null}'] }
        end

        conn = Faraday.new do |f|
          f.adapter :test, stubs
        end

        http = Http.new('secret-token', 'https://platform-api.max.ru', connection: conn)
        result = http.get('/updates', query: {})

        assert_equal [], result[:updates]
        assert_nil result[:marker]
        stubs.verify_stubbed_calls
      end

      def test_post_sends_json_body_and_auth
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/messages', '{"text":"hi"}') do |env|
            assert_equal 'secret-token', env.request_headers['Authorization']
            assert_match %r{application/json}, env.request_headers['Content-Type']
            [200, { 'Content-Type' => 'application/json' }, '{"message":{"body":{}}}']
          end
        end

        conn = Faraday.new do |f|
          f.adapter :test, stubs
        end

        http = Http.new('secret-token', 'https://platform-api.max.ru', connection: conn)
        result = http.post('/messages', query: { chat_id: 1 }, body: { text: 'hi' })

        assert result.key?(:message)
        stubs.verify_stubbed_calls
      end

      def test_raises_api_error_on_http_error
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.get('/updates') { [401, {}, '{"message":"unauthorized"}'] }
        end

        conn = Faraday.new do |f|
          f.adapter :test, stubs
        end

        http = Http.new('bad', 'https://platform-api.max.ru', connection: conn)

        err = assert_raises(ApiError) { http.get('/updates') }
        assert_equal 401, err.status
        assert_equal 'unauthorized', err.body[:message]
      end

      def test_delete_sends_query_and_auth
        stubs = Faraday::Adapter::Test::Stubs.new do |stub|
          stub.delete('/subscriptions') do |env|
            assert_equal 'tok', env.request_headers['Authorization']
            assert_equal 'https://h', env.params['url']
            [200, { 'Content-Type' => 'application/json' }, '{"success":true}']
          end
        end

        conn = Faraday.new do |f|
          f.adapter :test, stubs
        end

        http = Http.new('tok', 'https://platform-api.max.ru', connection: conn)
        result = http.delete('/subscriptions', query: { url: 'https://h' })
        assert_equal true, result[:success]
        stubs.verify_stubbed_calls
      end
    end
  end
end
