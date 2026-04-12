# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
    class FakeHttp
      attr_reader :response, :last_path, :last_body, :last_query

      def initialize(response)
        @response = response
        @last_path = nil
        @last_body = nil
        @last_query = nil
      end

      def post(path, query: nil, body: nil)
        @last_path = path
        @last_body = body
        @last_query = query
        @response
      end

      def get(path, query: nil)
        @last_path = path
        @last_query = query
        @response
      end

      def delete(path, query: nil)
        @last_path = path
        @last_query = query
        @response
      end

      def put(path, query: nil, body: nil)
        @last_path = path
        @last_body = body
        @last_query = query
        @response
      end
    end

    class ApiTest < Minitest::Test
      def test_rejects_blank_token
        assert_raises(ArgumentError) { Api.new(nil) }
        assert_raises(ArgumentError) { Api.new('   ') }
      end

      def test_send_message_requires_recipient
        api = Api.new('token')
        err = assert_raises(ArgumentError) { api.send_message('hi') }
        assert_match(/chat_id|user_id/, err.message)
      end

      def test_send_message_requires_payload
        api = Api.new('token')
        err = assert_raises(ArgumentError) { api.send_message(nil, chat_id: 1) }
        assert_match(/text|attachments|attachment|link/, err.message)
      end

      def test_set_webhook_rejects_invalid_url
        api = Api.new('token')
        assert_raises(ArgumentError) { api.set_webhook(url: 'not-a-url') }
        assert_raises(ArgumentError) { api.set_webhook(url: '') }
        assert_raises(ArgumentError) { api.set_webhook(url: 'ftp://example.com') }
      end

      def test_set_webhook_accepts_valid_url
        http = FakeHttp.new({})
        api = Api.new('token', http: http)
        api.set_webhook(url: 'https://example.com/webhook')
        assert_equal '/subscriptions', http.last_path
        assert_equal 'https://example.com/webhook', http.last_body[:url]
      end

      def test_me
        response = { user_id: 1, name: 'Test Bot', username: 'test_bot' }
        http = FakeHttp.new(response)
        api = Api.new('token', http: http)
        result = api.me
        assert_equal 1, result[:user_id]
        assert_equal '/bots', http.last_path
      end

      def test_chat_requires_chat_id
        api = Api.new('token')
        assert_raises(ArgumentError) { api.chat(nil) }
        assert_raises(ArgumentError) { api.chat('') }
        assert_raises(ArgumentError) { api.chat('   ') }
      end

      def test_chat
        response = { chat_id: 123, name: 'Test Chat' }
        http = FakeHttp.new(response)
        api = Api.new('token', http: http)
        result = api.chat(123)
        assert_equal 123, result[:chat_id]
        assert_equal '/chats/123', http.last_path
      end

      def test_get_message_requires_message_id
        api = Api.new('token')
        assert_raises(ArgumentError) { api.get_message(nil) }
        assert_raises(ArgumentError) { api.get_message('') }
      end

      def test_get_message
        response = { message_id: 42, body: { text: 'hello' } }
        http = FakeHttp.new(response)
        api = Api.new('token', http: http)
        result = api.get_message(42)
        assert_equal 42, result[:message_id]
        assert_equal '/messages/42', http.last_path
      end

      def test_edit_message_requires_message_id
        api = Api.new('token')
        assert_raises(ArgumentError) { api.edit_message(nil, 'text') }
        assert_raises(ArgumentError) { api.edit_message('', 'text') }
      end

      def test_edit_message
        response = { message_id: 42 }
        http = FakeHttp.new(response)
        api = Api.new('token', http: http)
        result = api.edit_message(42, 'updated text', format: 'markdown')
        assert_equal 42, result[:message_id]
        assert_equal '/messages/42', http.last_path
        assert_equal 'updated text', http.last_body[:text]
        assert_equal 'markdown', http.last_body[:format]
      end

      def test_delete_message_requires_message_id
        api = Api.new('token')
        assert_raises(ArgumentError) { api.delete_message(nil) }
        assert_raises(ArgumentError) { api.delete_message('') }
      end

      def test_delete_message
        http = FakeHttp.new({ success: true })
        api = Api.new('token', http: http)
        api.delete_message(42)
        assert_equal '/messages/42', http.last_path
      end

      def test_answer_callback_requires_id
        api = Api.new('token')
        assert_raises(ArgumentError) { api.answer_callback(nil) }
        assert_raises(ArgumentError) { api.answer_callback('') }
      end

      def test_answer_callback
        response = { success: true }
        http = FakeHttp.new(response)
        api = Api.new('token', http: http)
        api.answer_callback('cb_123', text: 'Done!', show_alert: true)
        assert_equal '/messages/callback', http.last_path
        assert_equal 'cb_123', http.last_body[:callback_query_id]
        assert_equal 'Done!', http.last_body[:text]
        assert_equal true, http.last_body[:show_alert]
      end
    end
  end
end
