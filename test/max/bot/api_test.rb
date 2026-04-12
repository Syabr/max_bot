# frozen_string_literal: true

require 'test_helper'

module Max
  module Bot
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
    end
  end
end
